import NIOCore

/// A representation of all possible D-Bus data types.
///
/// D-Bus has a well-defined type system that includes basic types (integers, strings, etc.)
/// and container types (arrays, structs, dictionaries, variants). This enum provides Swift
/// representations of all these types and handles marshaling/unmarshaling to the D-Bus wire format.
///
/// Basic types directly map to Swift primitive types, while container types use Swift collections
/// to represent their D-Bus counterparts.
///
/// - SeeAlso: [D-Bus Type System](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system)
/// - SeeAlso: [D-Bus Message Protocol - Marshaling](https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling)
public indirect enum DBusValue: Hashable, Sendable {
  /// A single byte (8 bits). D-Bus type code: 'y'.
  case byte(UInt8)

  /// A boolean value. D-Bus type code: 'b'.
  case boolean(Bool)

  /// A 16-bit signed integer. D-Bus type code: 'n'.
  case int16(Int16)

  /// A 16-bit unsigned integer. D-Bus type code: 'q'.
  case uint16(UInt16)

  /// A 32-bit signed integer. D-Bus type code: 'i'.
  case int32(Int32)

  /// A 32-bit unsigned integer. D-Bus type code: 'u'.
  case uint32(UInt32)

  /// A 64-bit signed integer. D-Bus type code: 'x'.
  case int64(Int64)

  /// A 64-bit unsigned integer. D-Bus type code: 't'.
  case uint64(UInt64)

  /// An IEEE 754 double-precision floating point number. D-Bus type code: 'd'.
  case double(Double)

  /// A UTF-8 encoded string. D-Bus type code: 's'.
  case string(String)

  /// A string following the D-Bus object path format rules. D-Bus type code: 'o'.
  case objectPath(String)

  /// A string following the D-Bus type signature format rules. D-Bus type code: 'g'.
  case signature(String)

  /// A 32-bit unsigned integer representing a file descriptor. D-Bus type code: 'h'.
  case unixFd(UInt32)

  /// A container type that can hold a value of any D-Bus type. D-Bus type code: 'v'.
  case variant(DBusVariant)

  /// An array of values all of the same type. D-Bus type code: 'a'.
  case array([DBusValue])

  /// A container of values of potentially different types. D-Bus type code: '(...)'.
  case structure([DBusValue])

  /// An associative array mapping keys to values. D-Bus type code: 'a{...}'.
  case dictionary([DBusValue: DBusValue])

  /// Returns the required byte alignment for a D-Bus type.
  ///
  /// D-Bus requires values to be aligned to specific byte boundaries based on their type.
  /// This method returns the alignment requirement in bytes for a given type signature.
  ///
  /// - Parameter typeSignature: The D-Bus type signature string.
  /// - Returns: The alignment requirement in bytes.
  /// - SeeAlso: [D-Bus Message Protocol - Alignment](https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling-alignment)
  static func alignment(for typeSignature: String) -> Int {
    guard let c = typeSignature.first else { return 1 }
    switch c {
    case "y": return 1  // BYTE
    case "n", "q": return 2  // INT16, UINT16
    case "b", "i", "u", "s", "o", "g", "h": return 4  // BOOLEAN, INT32, UINT32, STRING, OBJECT_PATH, SIGNATURE, UNIX_FD
    case "x", "t", "d": return 8  // INT64, UINT64, DOUBLE
    case "a": return 4  // ARRAY
    case "(": return 8  // STRUCT
    case "{": return 8  // DICT_ENTRY
    case "v": return 1  // VARIANT (signature is 1, value is aligned as per type)
    default: return 1
    }
  }

  /// Parses a D-Bus value from a ByteBuffer based on the provided type signature.
  ///
  /// This method reads data from the buffer according to the D-Bus marshaling rules,
  /// ensuring proper alignment and byte order conversions.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to read from. The buffer's reader index will be advanced.
  ///   - typeSignature: The D-Bus type signature for the value to parse.
  ///   - byteOrder: The byte order (endianness) of the data.
  /// - Returns: The parsed D-Bus value.
  /// - Throws: `DBusError` if the data cannot be parsed according to the type signature.
  static func parse(from buffer: inout ByteBuffer, typeSignature: String, byteOrder: Endianness)
    throws -> DBusValue
  {
    guard let typeChar = typeSignature.first else {
      throw DBusError.invalidSignature
    }
    // Align buffer before reading value
    let alignment = alignment(for: typeSignature)
    buffer.alignReader(to: alignment)
    switch typeChar {
    case "y": return .byte(try buffer.requireInteger())
    case "b":
      // Boolean is a 32-bit integer with value 0 or 1, align to 4 bytes
      buffer.alignReader(to: 4)
      return .boolean(try buffer.requireInteger(endianness: byteOrder) as UInt32 != 0)
    case "n": return .int16(try buffer.requireInteger(endianness: byteOrder))
    case "q": return .uint16(try buffer.requireInteger(endianness: byteOrder))
    case "i": return .int32(try buffer.requireInteger(endianness: byteOrder))
    case "u": return .uint32(try buffer.requireInteger(endianness: byteOrder))
    case "x": return .int64(try buffer.requireInteger(endianness: byteOrder))
    case "t": return .uint64(try buffer.requireInteger(endianness: byteOrder))
    case "d": return .double(try buffer.requireDouble(endianness: byteOrder))
    case "s": return .string(try DBusString.read(from: &buffer, byteOrder: byteOrder))
    case "o": return .objectPath(try DBusString.read(from: &buffer, byteOrder: byteOrder))
    case "g": return .signature(try DBusString.readSignature(from: &buffer, byteOrder: byteOrder))
    case "h": return .unixFd(try buffer.requireInteger(endianness: byteOrder))
    case "v": return .variant(try DBusVariant(from: &buffer, byteOrder: byteOrder))
    case "a":
      let elementSig = String(typeSignature.dropFirst())
      let arrayLen = try buffer.requireInteger(endianness: byteOrder) as UInt32

      // If array length is 0, there's no need to align further
      if arrayLen == 0 {
        if elementSig.starts(with: "{") {
          // Create empty dictionary with the correct type signature
          return .dictionary([:])
        } else {
          // Create empty array with the correct type signature
          // Store the element type so we can preserve it
          return .array([])
        }
      }

      // Store the current position to track how much we've read
      let _ = buffer.readerIndex

      // Align the buffer to the element's alignment
      buffer.alignReader(to: Self.alignment(for: elementSig))

      // Track the maximum bytes we should read from the array
      let maxArrayBytes = Int(arrayLen)
      let arrayEndPosition = buffer.readerIndex + maxArrayBytes

      if elementSig.starts(with: "{") {
        // Parse the dictionary entry signatures
        let inner = String(elementSig.dropFirst().dropLast())

        // The dictionary key and value types
        var keyType = ""
        var valueType = ""

        // Try to parse the key and value types correctly
        var remainingSignature = inner
        if !remainingSignature.isEmpty {
          keyType = try parseNextTypeSignature(from: &remainingSignature)
          if !remainingSignature.isEmpty {
            valueType = remainingSignature
          }
        }

        if keyType.isEmpty || valueType.isEmpty {
          throw DBusError.invalidSignature
        }

        var dict: [DBusValue: DBusValue] = [:]

        // Read dictionary entries until we reach the array end
        while buffer.readerIndex < arrayEndPosition {
          buffer.alignReader(to: 8)  // Dict entries are aligned to 8 bytes

          // Ensure we don't read past the array end
          if buffer.readerIndex >= arrayEndPosition {
            break
          }

          let key = try DBusValue.parse(from: &buffer, typeSignature: keyType, byteOrder: byteOrder)
          let value = try DBusValue.parse(
            from: &buffer, typeSignature: valueType, byteOrder: byteOrder)
          dict[key] = value
        }

        // Ensure we've read exactly the array length
        if buffer.readerIndex > arrayEndPosition {
          throw DBusError.invalidHeader
        }

        // Skip any remaining bytes in the array (shouldn't happen if parsing is correct)
        if buffer.readerIndex < arrayEndPosition {
          let remaining = arrayEndPosition - buffer.readerIndex
          buffer.moveReaderIndex(forwardBy: remaining)
        }

        return .dictionary(dict)
      } else {
        var elements: [DBusValue] = []

        // Read array elements until we reach the array end
        while buffer.readerIndex < arrayEndPosition {
          // Ensure we don't read past the array end
          if buffer.readerIndex >= arrayEndPosition {
            break
          }

          elements.append(
            try DBusValue.parse(from: &buffer, typeSignature: elementSig, byteOrder: byteOrder))
        }

        // Ensure we've read exactly the array length
        if buffer.readerIndex > arrayEndPosition {
          throw DBusError.invalidHeader
        }

        // Skip any remaining bytes in the array (shouldn't happen if parsing is correct)
        if buffer.readerIndex < arrayEndPosition {
          let remaining = arrayEndPosition - buffer.readerIndex
          buffer.moveReaderIndex(forwardBy: remaining)
        }

        return .array(elements)
      }
    case "(":
      // Handle struct parsing more carefully
      let inner = String(typeSignature.dropFirst().dropLast())
      var fields: [DBusValue] = []

      // Parse each type signature in the struct
      var remaining = inner
      while !remaining.isEmpty {
        let fieldSig = try parseNextTypeSignature(from: &remaining)
        fields.append(
          try DBusValue.parse(from: &buffer, typeSignature: fieldSig, byteOrder: byteOrder))
      }

      return .structure(fields)
    default:
      throw DBusError.unsupportedType
    }
  }

  /// Helper method to parse the next complete type signature from a compound signature
  internal static func parseNextTypeSignature(from signature: inout String) throws -> String {
    guard !signature.isEmpty else {
      throw DBusError.invalidSignature
    }

    let firstChar = signature.removeFirst()
    var result = String(firstChar)

    // Handle container types that need special parsing
    switch firstChar {
    case "a":
      // Array type needs its element type
      if signature.isEmpty {
        throw DBusError.invalidSignature
      }

      // If array of dict entries, parse the entire dict entry type
      if signature.first == "{" {
        var entryDepth = 0
        var entryType = ""

        // Parse the complete dict entry type
        while !signature.isEmpty {
          let char = signature.removeFirst()
          entryType.append(char)

          if char == "{" {
            entryDepth += 1
          } else if char == "}" {
            entryDepth -= 1
            if entryDepth == 0 {
              break  // Complete dict entry type
            }
          }
        }

        result.append(entryType)
      } else {
        // Regular array, parse the element type
        let elementType = try parseNextTypeSignature(from: &signature)
        result.append(elementType)
      }

    case "(", "{":
      // Struct or dict entry type
      var depth = 1
      var innerType = ""

      // Parse until matching closing parenthesis/brace
      while !signature.isEmpty && depth > 0 {
        let char = signature.removeFirst()
        innerType.append(char)

        if char == "(" || char == "{" {
          depth += 1
        } else if char == ")" || char == "}" {
          depth -= 1
          if depth == 0 && char == ")" {
            break  // Complete struct type
          } else if depth == 0 && char == "}" {
            break  // Complete dict entry type
          }
        }
      }

      result.append(innerType)

    default:
      // Basic type, already handled by taking the first character
      break
    }

    return result
  }
}

extension DBusValue {
  /// Writes this D-Bus value to a ByteBuffer according to the D-Bus marshaling rules.
  ///
  /// This method handles proper alignment and endianness conversion when writing values.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to write to. The buffer's writer index will be advanced.
  ///   - byteOrder: The byte order (endianness) to use when writing multi-byte values.
  func write(to buffer: inout ByteBuffer, byteOrder: Endianness) {
    switch self {
    case .byte(let v):
      buffer.writeInteger(v)
    case .boolean(let v):
      buffer.alignWriter(to: 4)
      buffer.writeInteger(v ? UInt32(1) : UInt32(0), endianness: byteOrder)
    case .int16(let v):
      buffer.alignWriter(to: 2)
      buffer.writeInteger(v, endianness: byteOrder)
    case .uint16(let v):
      buffer.alignWriter(to: 2)
      buffer.writeInteger(v, endianness: byteOrder)
    case .int32(let v):
      buffer.alignWriter(to: 4)
      buffer.writeInteger(v, endianness: byteOrder)
    case .uint32(let v):
      buffer.alignWriter(to: 4)
      buffer.writeInteger(v, endianness: byteOrder)
    case .int64(let v):
      buffer.alignWriter(to: 8)
      buffer.writeInteger(v, endianness: byteOrder)
    case .uint64(let v):
      buffer.alignWriter(to: 8)
      buffer.writeInteger(v, endianness: byteOrder)
    case .double(let v):
      buffer.alignWriter(to: 8)
      buffer.writeInteger(v.bitPattern, endianness: byteOrder)
    case .string(let s):
      buffer.alignWriter(to: 4)
      let bytes = Array(s.utf8)
      buffer.writeInteger(UInt32(bytes.count), endianness: byteOrder)
      buffer.writeBytes(bytes)
      buffer.writeInteger(UInt8(0))
    case .objectPath(let s):
      buffer.alignWriter(to: 4)
      let bytes = Array(s.utf8)
      buffer.writeInteger(UInt32(bytes.count), endianness: byteOrder)
      buffer.writeBytes(bytes)
      buffer.writeInteger(UInt8(0))
    case .signature(let s):
      buffer.writeInteger(UInt8(s.utf8.count))
      buffer.writeBytes(Array(s.utf8))
      buffer.writeInteger(UInt8(0))
    case .unixFd(let v):
      buffer.alignWriter(to: 4)
      buffer.writeInteger(v, endianness: byteOrder)
    case .variant(let v):
      v.write(to: &buffer, byteOrder: byteOrder)
    case .array(let arr):
      buffer.alignWriter(to: 4)
      let start = buffer.writerIndex
      buffer.writeInteger(UInt32(0), endianness: byteOrder)  // Placeholder for length

      // Only align and write content if there are elements
      if !arr.isEmpty {
        let align = arr.first.map { DBusValue.alignment(for: $0.dbusTypeSignature) } ?? 1
        buffer.alignWriter(to: align)
        let arrayStart = buffer.writerIndex
        for el in arr {
          el.write(to: &buffer, byteOrder: byteOrder)
        }
        let arrayEnd = buffer.writerIndex
        let len = UInt32(arrayEnd - arrayStart)
        buffer.setInteger(len, at: start, endianness: byteOrder)
      }
    case .structure(let fields):
      buffer.alignWriter(to: 8)
      for f in fields {
        f.write(to: &buffer, byteOrder: byteOrder)
      }
    case .dictionary(let dict):
      buffer.alignWriter(to: 4)
      let start = buffer.writerIndex
      buffer.writeInteger(UInt32(0), endianness: byteOrder)  // Placeholder for length

      // Only align and write content if there are elements
      if !dict.isEmpty {
        buffer.alignWriter(to: 8)
        let dictStart = buffer.writerIndex
        for (k, v) in dict {
          buffer.alignWriter(to: 8)
          k.write(to: &buffer, byteOrder: byteOrder)
          v.write(to: &buffer, byteOrder: byteOrder)
        }
        let dictEnd = buffer.writerIndex
        let len = UInt32(dictEnd - dictStart)
        buffer.setInteger(len, at: start, endianness: byteOrder)
      }
    }
  }

  /// Returns the D-Bus type signature string for this value.
  ///
  /// Each D-Bus value has a corresponding type signature that describes its type.
  /// This computed property returns the signature string for the current value.
  ///
  /// - Returns: A string containing the D-Bus type signature.
  /// - SeeAlso: [D-Bus Type Signatures](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system)
  var dbusTypeSignature: String {
    switch self {
    case .byte: return "y"
    case .boolean: return "b"
    case .int16: return "n"
    case .uint16: return "q"
    case .int32: return "i"
    case .uint32: return "u"
    case .int64: return "x"
    case .uint64: return "t"
    case .double: return "d"
    case .string: return "s"
    case .objectPath: return "o"
    case .signature: return "g"
    case .unixFd: return "h"
    case .variant: return "v"
    case .array(let arr):
      if let firstElement = arr.first {
        return "a" + firstElement.dbusTypeSignature
      } else {
        // Use the stored element type for empty arrays
        return "ay"
      }
    case .structure(let fields):
      return "(" + fields.map { $0.dbusTypeSignature }.joined() + ")"
    case .dictionary(let dict):
      if let (k, v) = dict.first {
        return "a{" + k.dbusTypeSignature + v.dbusTypeSignature + "}"
      } else {
        // Use standard string-variant dictionary for empty dictionaries
        return "a{sv}"
      }
    }
  }
}
