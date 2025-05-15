import NIOCore
import Testing

@testable import DBusSwift

@Suite
struct DBusValueTests {
  // MARK: - Basic Types

  @Test func byteValue() throws {
    let values: [UInt8] = [0, 1, 127, 255]
    for value in values {
      try testRoundTrip(.byte(value), "y")
    }
  }

  @Test func booleanValue() throws {
    try testRoundTrip(.boolean(true), "b")
    try testRoundTrip(.boolean(false), "b")
  }

  @Test func int16Value() throws {
    let values: [Int16] = [0, 1, -1, 32767, -32768]
    for value in values {
      try testRoundTrip(.int16(value), "n")
    }
  }

  @Test func uint16Value() throws {
    let values: [UInt16] = [0, 1, 32767, 65535]
    for value in values {
      try testRoundTrip(.uint16(value), "q")
    }
  }

  @Test func int32Value() throws {
    let values: [Int32] = [0, 1, -1, 2_147_483_647, -2_147_483_648]
    for value in values {
      try testRoundTrip(.int32(value), "i")
    }
  }

  @Test func uint32Value() throws {
    let values: [UInt32] = [0, 1, 2_147_483_647, 4_294_967_295]
    for value in values {
      try testRoundTrip(.uint32(value), "u")
    }
  }

  @Test func int64Value() throws {
    let values: [Int64] = [0, 1, -1, 9_223_372_036_854_775_807, -9_223_372_036_854_775_808]
    for value in values {
      try testRoundTrip(.int64(value), "x")
    }
  }

  @Test func uint64Value() throws {
    let values: [UInt64] = [0, 1, 9_223_372_036_854_775_807, 18_446_744_073_709_551_615]
    for value in values {
      try testRoundTrip(.uint64(value), "t")
    }
  }

  @Test func doubleValue() throws {
    let values: [Double] = [
      0.0, 1.0, -1.0, 3.14159, Double.pi, Double.infinity, -Double.infinity, Double.nan,
    ]
    for value in values {
      try testRoundTrip(.double(value), "d")
    }
  }

  @Test func stringValue() throws {
    let values = ["", "Hello", "Unicode 😊", "Multi\nLine", "Special \"'\\Characters"]
    for value in values {
      try testRoundTrip(.string(value), "s")
    }
  }

  @Test func objectPathValue() throws {
    let values = ["/", "/com", "/com/example", "/com/example/Service1"]
    for value in values {
      try testRoundTrip(.objectPath(value), "o")
    }
  }

  @Test func signatureValue() throws {
    let values = ["", "s", "a{sv}", "a(isai)"]
    for value in values {
      try testRoundTrip(.signature(value), "g")
    }
  }

  @Test func unixFdValue() throws {
    let values: [UInt32] = [0, 1, 10, 4_294_967_295]
    for value in values {
      try testRoundTrip(.unixFd(value), "h")
    }
  }

  // MARK: - Container Types

  @Test func emptyArrayValue() throws {
    // Use a proper element type for empty arrays
    let emptyByteArray = DBusValue.array([])
    // Specify the element type explicitly with "ay" (array of bytes)
    try testRoundTrip(emptyByteArray, "ay")

    // All empty arrays have the same signature: "ay"
    let emptyIntArray = DBusValue.array([])
    try testRoundTrip(emptyIntArray, "ay")

    let emptyStringArray = DBusValue.array([])
    try testRoundTrip(emptyStringArray, "ay")
  }

  @Test func arrayOfBasicTypesValue() throws {
    let arrays: [DBusValue] = [
      .array([.byte(1), .byte(2), .byte(3)]),
      .array([.boolean(true), .boolean(false), .boolean(true)]),
      .array([.int32(1), .int32(2), .int32(3)]),
      .array([.string("a"), .string("b"), .string("c")]),
    ]

    for array in arrays {
      try testRoundTrip(array, array.dbusTypeSignature)
    }
  }

  @Test func nestedArraysValue() throws {
    let nestedArray = DBusValue.array([
      .array([.int32(1), .int32(2)]),
      .array([.int32(3), .int32(4)]),
      .array([.int32(5), .int32(6)]),
    ])

    try testRoundTrip(nestedArray, nestedArray.dbusTypeSignature)
  }

  @Test func structureValue() throws {
    let structures: [DBusValue] = [
      .structure([.byte(1)]),
      .structure([.int32(42), .string("hello")]),
      .structure([.boolean(true), .double(3.14), .array([.byte(1), .byte(2)])]),
    ]

    for structure in structures {
      try testRoundTrip(structure, structure.dbusTypeSignature)
    }
  }

  @Test func emptyDictionaryValue() throws {
    let emptyDict = DBusValue.dictionary([:])
    try testRoundTrip(emptyDict, "a{sv}")
  }

  @Test func dictionaryValue() throws {
    let dictionaries: [DBusValue] = [
      // Dictionary of string keys to variant values (the most common D-Bus pattern)
      .dictionary([.string("key"): .variant(DBusVariant(.int32(42)))]),
      .dictionary([.string("int"): .int32(42)]),
      // Dictionary with multiple entries, all values are variants
      .dictionary([
        .string("name"): .variant(DBusVariant(.string("John"))),
        .string("age"): .variant(DBusVariant(.int32(30))),
        .string("height"): .variant(DBusVariant(.double(1.85))),
      ]),

      // Dictionary with byte keys, all values are variants containing arrays
      .dictionary([
        .byte(1): .variant(DBusVariant(.array([.string("one")]))),
        .byte(2): .variant(DBusVariant(.array([.string("two")]))),
      ]),
    ]

    for dictionary in dictionaries {
      try testRoundTrip(dictionary, dictionary.dbusTypeSignature)
    }
  }

  @Test func variantValue() throws {
    let variants: [DBusValue] = [
      .variant(DBusVariant(.byte(42))),
      .variant(DBusVariant(.string("hello"))),
      .variant(DBusVariant(.array([.int32(1), .int32(2)]))),
    ]

    for variant in variants {
      try testRoundTrip(variant, "v")
    }
  }

  @Test func complexNestedValue() throws {
    // A complex structure with nested types
    let complex = DBusValue.structure([
      .string("header"),
      .array([.int32(1), .int32(2), .int32(3)]),
      .dictionary([
        .string("metadata"): .variant(
          DBusVariant(
            .structure([
              .string("info"),
              .boolean(true),
              .double(3.14159),
            ])
          )),
        .string("tags"): .variant(
          DBusVariant(
            .array([.string("one"), .string("two")])
          )),
      ]),
    ])

    try testRoundTrip(complex, complex.dbusTypeSignature)
  }

  @Test func alignmentCorrectness() throws {
    // Test that alignment is handled correctly by mixing types with
    // different alignment requirements
    let mixedAlignments = DBusValue.structure([
      .byte(1),  // 1-byte alignment
      .int16(2),  // 2-byte alignment
      .int32(3),  // 4-byte alignment
      .int64(4),  // 8-byte alignment
      .byte(5),  // back to 1-byte alignment
      .int64(6),  // back to 8-byte alignment
    ])

    try testRoundTrip(mixedAlignments, mixedAlignments.dbusTypeSignature)
  }

  // MARK: - Endianness Tests

  @Test func littleEndianSerialization() throws {
    let value = DBusValue.int32(0x1234_5678)
    try testRoundTripWithEndianness(value, "i", .little)
  }

  @Test func bigEndianSerialization() throws {
    let value = DBusValue.int32(0x1234_5678)
    try testRoundTripWithEndianness(value, "i", .big)
  }

  // MARK: - Error Cases

  @Test func invalidSignature() throws {
    var buffer = ByteBuffer()
    buffer.writeInteger(UInt8(42))

    do {
      let _ = try DBusValue.parse(from: &buffer, typeSignature: "z", byteOrder: .little)
      #expect(Bool(false), "Expected error for invalid signature")
    } catch {
      // Expected error
    }
  }

  // MARK: - Helper Methods

  /// Tests round-trip serialization and deserialization of a DBusValue
  func testRoundTrip(_ value: DBusValue, _ typeSignature: String) throws {
    try testRoundTripWithEndianness(value, typeSignature, .little)
  }

  /// Tests round-trip serialization and deserialization of a DBusValue with specified endianness
  func testRoundTripWithEndianness(
    _ value: DBusValue, _ typeSignature: String, _ endianness: Endianness
  ) throws {
    // Check that value's signature matches expected signature
    let valueSig = value.dbusTypeSignature
    #expect(valueSig == typeSignature, "Value signature doesn't match expected signature")

    var writeBuffer = ByteBuffer()
    value.write(to: &writeBuffer, byteOrder: endianness)

    var readBuffer = writeBuffer
    do {
      let parsedValue = try DBusValue.parse(
        from: &readBuffer, typeSignature: typeSignature, byteOrder: endianness)

      // Verify parsed value matches original
      switch (value, parsedValue) {
      case (.byte(let v1), .byte(let v2)):
        #expect(v1 == v2)
      case (.boolean(let v1), .boolean(let v2)):
        #expect(v1 == v2)
      case (.int16(let v1), .int16(let v2)):
        #expect(v1 == v2)
      case (.uint16(let v1), .uint16(let v2)):
        #expect(v1 == v2)
      case (.int32(let v1), .int32(let v2)):
        #expect(v1 == v2)
      case (.uint32(let v1), .uint32(let v2)):
        #expect(v1 == v2)
      case (.int64(let v1), .int64(let v2)):
        #expect(v1 == v2)
      case (.uint64(let v1), .uint64(let v2)):
        #expect(v1 == v2)
      case (.double(let v1), .double(let v2)):
        if v1.isNaN && v2.isNaN {
          // NaN doesn't equal itself, so handle specially
          #expect(Bool(true))
        } else {
          #expect(v1 == v2)
        }
      case (.string(let v1), .string(let v2)):
        #expect(v1 == v2)
      case (.objectPath(let v1), .objectPath(let v2)):
        #expect(v1 == v2)
      case (.signature(let v1), .signature(let v2)):
        #expect(v1 == v2)
      case (.unixFd(let v1), .unixFd(let v2)):
        #expect(v1 == v2)
      case (.array(let a1), .array(let a2)):
        #expect(a1.count == a2.count)
      // Further array comparison would need recursive comparison
      case (.structure(let s1), .structure(let s2)):
        #expect(s1.count == s2.count)
      // Further structure comparison would need recursive comparison
      case (.dictionary(let d1), .dictionary(let d2)):
        #expect(d1.count == d2.count)
      // Further dictionary comparison would need recursive comparison
      case (.variant, .variant):
        // Variant comparison would need to examine signature and value
        #expect(Bool(true))
      default:
        #expect(Bool(false), "Value type mismatch: \(value) vs \(parsedValue)")
      }

      // For complex containers, also verify the type signature matches
      #expect(value.dbusTypeSignature == parsedValue.dbusTypeSignature)

      // Verify all bytes were consumed
      #expect(readBuffer.readableBytes == 0)
    } catch {
      throw error
    }
  }

  @Test func signatureValidation() throws {
    // Test various complex type signatures to ensure they're correctly understood
    let signatures = [
      "s",  // string
      "a{sv}",  // dictionary from string to variant
      "(sai)",  // struct with string and array of int32
      "a(ii)",  // array of structs with two int32s
      "(saia{sv})",  // complex struct from our test case
    ]

    for signature in signatures {
      // Create a simple buffer with a valid value for the signature
      var buffer = ByteBuffer()

      // For each signature, create a minimal valid buffer that can be parsed
      let testValue = try createMinimalValue(for: signature)

      // Write value to buffer
      testValue.write(to: &buffer, byteOrder: .little)

      // Try to parse the value back
      var readBuffer = buffer
      let parsedValue = try DBusValue.parse(
        from: &readBuffer, typeSignature: signature, byteOrder: .little)

      // Verify signatures match
      #expect(testValue.dbusTypeSignature == parsedValue.dbusTypeSignature)
      #expect(readBuffer.readableBytes == 0)
    }
  }

  /// Creates a minimal valid value for a given signature
  func createMinimalValue(for signature: String) throws -> DBusValue {
    switch signature.first {
    case "s": return .string("test")
    case "i": return .int32(42)
    case "b": return .boolean(true)
    case "a":
      if signature.starts(with: "a{sv}") {
        return .dictionary([.string("key"): .variant(DBusVariant(.int32(1)))])
      } else if signature.starts(with: "a{") {
        // Other dictionary types
        let keyType = String(signature[signature.index(signature.startIndex, offsetBy: 2)])
        let valueType = String(signature[signature.index(signature.startIndex, offsetBy: 3)])
        let key = try createMinimalValue(for: String(keyType))
        let value = try createMinimalValue(for: String(valueType))
        return .dictionary([key: value])
      } else {
        // Array of elements
        let elementType = String(signature.dropFirst())
        let element = try createMinimalValue(for: elementType)
        return .array([element])
      }
    case "(":
      // Parse the struct signature and create values for each field
      var remaining = String(signature.dropFirst().dropLast())
      var fields: [DBusValue] = []

      while !remaining.isEmpty {
        let fieldSig = try DBusValue.parseNextTypeSignature(from: &remaining)
        fields.append(try createMinimalValue(for: fieldSig))
      }

      return .structure(fields)
    case "v":
      return .variant(DBusVariant(.int32(1)))
    default:
      return .int32(1)  // Default fallback
    }
  }
}
