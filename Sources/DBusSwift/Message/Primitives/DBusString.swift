import NIOCore

/// Helper for handling D-Bus string-like types.
///
/// D-Bus defines several string-like types that share a similar marshaling format but with different encoding requirements:
/// - STRING: A UTF-8 encoded string, null-terminated (type code 's')
/// - OBJECT_PATH: A UTF-8 encoded string following the object path format rules, null-terminated (type code 'o')
/// - SIGNATURE: An ASCII encoded string following the type signature format rules, null-terminated (type code 'g')
///
/// String and object path types use the same format: a 32-bit length followed by the UTF-8 string data and a null terminator.
/// Signature strings use a more compact 8-bit length followed by the ASCII signature data and a null terminator.
///
/// - SeeAlso: [D-Bus Specification - Basic Types](https://dbus.freedesktop.org/doc/dbus-specification.html#basic-types)
/// - SeeAlso: [D-Bus Specification - String Marshaling](https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling-signature)
struct DBusString {
  /// Reads a D-Bus STRING or OBJECT_PATH value.
  ///
  /// From the D-Bus specification:
  /// > STRING: A UTF-8 string. Must be valid UTF-8. Must be nul terminated. Must not contain nul bytes.
  ///
  /// The format for these types is:
  /// 1. A UINT32 length in bytes (not including the terminating null character)
  /// 2. The string bytes themselves as non-null UTF-8
  /// 3. A single NULL byte
  ///
  /// - Parameters:
  ///   - buffer: The buffer to read from
  ///   - byteOrder: The byte order (endianness) to use when reading
  /// - Returns: The decoded string
  /// - Throws: An error if the string is invalid or can't be decoded as UTF-8
  ///
  /// - SeeAlso: [D-Bus Specification - STRING](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system-text)
  /// - SeeAlso: [D-Bus Specification - OBJECT_PATH](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system-objectpath)
  static func read(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
    // Check if we have enough bytes for the length
    guard buffer.readableBytes >= 4 else {
      throw DBusError.invalidString
    }

    // Keep track of original buffer position for error reporting
    let originalPosition = buffer.readerIndex

    let length: UInt32
    do {
      length = try buffer.requireInteger(endianness: byteOrder)
    } catch {
      throw DBusError.invalidString
    }

    // Ensure the length is reasonable compared to buffer size
    guard length <= 65535, length <= UInt32(buffer.readableBytes) else {
      // Reset buffer position on error
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidString
    }

    // Check if we have enough bytes for the string data plus null terminator
    guard buffer.readableBytes >= Int(length) + 1 else {
      // Reset buffer position on error
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidString
    }

    let bytes: [UInt8]
    do {
      bytes = try buffer.requireBytes(length: Int(length))
    } catch {
      // Reset buffer position on error
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidString
    }

    // Check for null terminator
    guard let nullTerminator = buffer.readInteger(as: UInt8.self), nullTerminator == 0 else {
      // Reset buffer position on error
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidString
    }

    // Check that the bytes don't contain internal null characters (not allowed in D-Bus strings)
    guard !bytes.contains(0) else {
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidString
    }

    // Check that the bytes are valid UTF-8
    guard let result = String(validating: bytes, as: UTF8.self) else {
      buffer.moveReaderIndex(to: originalPosition)
      throw DBusError.invalidUTF8
    }

    return result
  }

  /// Writes a D-Bus STRING or OBJECT_PATH value to a buffer.
  ///
  /// From the D-Bus specification:
  /// > STRING: A UTF-8 string. Must be valid UTF-8. Must be nul terminated. Must not contain nul bytes.
  ///
  /// The format is:
  /// 1. A UINT32 length in bytes (not including the terminating null character)
  /// 2. The string bytes themselves as non-null UTF-8
  /// 3. A single NULL byte
  ///
  /// - Parameters:
  ///   - string: The string to write
  ///   - buffer: The buffer to write to
  ///   - byteOrder: The byte order (endianness) to use when writing
  ///
  /// - SeeAlso: [D-Bus Specification - STRING](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system-text)
  static func write(_ string: String, to buffer: inout ByteBuffer, byteOrder: Endianness) {
    let bytes = Array(string.utf8)
    buffer.writeInteger(UInt32(bytes.count), endianness: byteOrder)
    buffer.writeBytes(bytes)
    buffer.writeInteger(UInt8(0))
  }

  /// Reads a D-Bus SIGNATURE value.
  ///
  /// From the D-Bus specification:
  /// > SIGNATURE: A string in the D-Bus type system's notation. Must be valid. Must be nul terminated. Must not contain nul bytes.
  ///
  /// The D-Bus specification requires signatures to use only ASCII characters from the D-Bus type system notation.
  ///
  /// The format for signatures is:
  /// 1. A BYTE specifying the length in bytes (not including the terminating null character)
  /// 2. The signature characters themselves (as ASCII)
  /// 3. A single NULL byte
  ///
  /// Signature strings are more compact than regular strings, using a single byte for length
  /// (limiting signatures to 255 characters). This is appropriate since signatures are usually short.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to read from
  ///   - byteOrder: The byte order (endianness) to use when reading
  /// - Returns: The decoded signature string
  /// - Throws: An error if the signature is invalid or can't be decoded
  ///
  /// - SeeAlso: [D-Bus Specification - SIGNATURE](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system-signature)
  /// - SeeAlso: [D-Bus Specification - Type Signatures](https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-signatures)
  static func readSignature(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
    // Check if we have enough bytes for the length
    guard buffer.readableBytes >= 1 else {
      throw DBusError.invalidSignature
    }

    let length = try buffer.requireInteger() as UInt8

    // Check if we have enough bytes for the signature data plus null terminator
    guard buffer.readableBytes >= Int(length) + 1 else {
      throw DBusError.invalidSignature
    }

    let bytes = try buffer.requireBytes(length: Int(length))

    // Check for null terminator
    guard let nullTerminator = buffer.readInteger(as: UInt8.self), nullTerminator == 0 else {
      throw DBusError.invalidSignature
    }

    // For signatures, we use ASCII encoding as per D-Bus spec
    // The String constructor with ASCII is safer here since signatures should contain only ASCII characters
    return String(decoding: bytes, as: UTF8.self)
  }

  /// Writes a D-Bus SIGNATURE value to a buffer.
  ///
  /// From the D-Bus specification:
  /// > SIGNATURE: A string in the D-Bus type system's notation. Must be valid. Must be nul terminated. Must not contain nul bytes.
  ///
  /// The format is:
  /// 1. A BYTE specifying the length in bytes (not including the terminating null character)
  /// 2. The signature characters themselves (as ASCII)
  /// 3. A single NULL byte
  ///
  /// - Note: Signatures are limited to 255 characters due to the 8-bit length field.
  ///
  /// - Parameters:
  ///   - signature: The signature string to write
  ///   - buffer: The buffer to write to
  ///   - byteOrder: The byte order (endianness) used when writing
  ///
  /// - SeeAlso: [D-Bus Specification - SIGNATURE](https://dbus.freedesktop.org/doc/dbus-specification.html#type-system-signature)
  static func writeSignature(_ signature: String, to buffer: inout ByteBuffer) {
    precondition(signature.utf8.count <= 255, "Signature is too long (must be <= 255 bytes)")

    // Ensure signature only contains ASCII characters
    precondition(
      signature.allSatisfy { $0.isASCII }, "Signature must contain only ASCII characters")

    let bytes = Array(signature.utf8)
    buffer.writeInteger(UInt8(bytes.count))
    buffer.writeBytes(bytes)
    buffer.writeInteger(UInt8(0))
  }
}
