import Testing
@testable import DBusSwift

/// Tests for the DBusType enum and related functionality.
@Suite("DBusTypes Tests")
struct DBusTypesTests {
    /// Tests the string value conversion for DBusType enum.
    @Test("DBusType String Value")
    func testDBusTypeStringValue() throws {
        // Test basic types
        #expect(DBusType.byte.stringValue() == "y")
        #expect(DBusType.boolean.stringValue() == "b")
        #expect(DBusType.int16.stringValue() == "n")
        #expect(DBusType.uint16.stringValue() == "q")
        #expect(DBusType.int32.stringValue() == "i")
        #expect(DBusType.uint32.stringValue() == "u")
        #expect(DBusType.int64.stringValue() == "x")
        #expect(DBusType.uint64.stringValue() == "t")
        #expect(DBusType.double.stringValue() == "d")
        #expect(DBusType.string.stringValue() == "s")
        #expect(DBusType.objectPath.stringValue() == "o")
        #expect(DBusType.signature.stringValue() == "g")
        
        // Test container types
        #expect(DBusType.array.stringValue() == "a")
        #expect(DBusType.variant.stringValue() == "v")
        #expect(DBusType.struct.stringValue() == "r")
        #expect(DBusType.dictEntry.stringValue() == "e")
        
        // Test invalid type
        #expect(DBusType.invalid.stringValue() == "")
    }
    
    /// Tests the initialization of DBusType from string values.
    @Test("DBusType From String")
    func testDBusTypeFromString() throws {
        // Test basic types
        #expect(DBusType(stringValue: "y")?.rawValue == DBusType.byte.rawValue)
        #expect(DBusType(stringValue: "b")?.rawValue == DBusType.boolean.rawValue)
        #expect(DBusType(stringValue: "n")?.rawValue == DBusType.int16.rawValue)
        #expect(DBusType(stringValue: "q")?.rawValue == DBusType.uint16.rawValue)
        #expect(DBusType(stringValue: "i")?.rawValue == DBusType.int32.rawValue)
        #expect(DBusType(stringValue: "u")?.rawValue == DBusType.uint32.rawValue)
        #expect(DBusType(stringValue: "x")?.rawValue == DBusType.int64.rawValue)
        #expect(DBusType(stringValue: "t")?.rawValue == DBusType.uint64.rawValue)
        #expect(DBusType(stringValue: "d")?.rawValue == DBusType.double.rawValue)
        #expect(DBusType(stringValue: "s")?.rawValue == DBusType.string.rawValue)
        #expect(DBusType(stringValue: "o")?.rawValue == DBusType.objectPath.rawValue)
        #expect(DBusType(stringValue: "g")?.rawValue == DBusType.signature.rawValue)
        
        // Test container types
        #expect(DBusType(stringValue: "a")?.rawValue == DBusType.array.rawValue)
        #expect(DBusType(stringValue: "v")?.rawValue == DBusType.variant.rawValue)
        #expect(DBusType(stringValue: "r")?.rawValue == DBusType.struct.rawValue)
        #expect(DBusType(stringValue: "e")?.rawValue == DBusType.dictEntry.rawValue)
        
        // Test invalid inputs
        #expect(DBusType(stringValue: "") == nil)
        #expect(DBusType(stringValue: "ab") == nil)
        #expect(DBusType(stringValue: "z") == nil)
    }
    
    /// Tests the conversion from DBusType to C type constants.
    @Test("DBusType To CType")
    func testDBusTypeToCType() throws {
        // Test basic types
        #expect(DBusType.byte.toCType() == DBusType.byte.rawValue)
        #expect(DBusType.boolean.toCType() == DBusType.boolean.rawValue)
        #expect(DBusType.int16.toCType() == DBusType.int16.rawValue)
        #expect(DBusType.uint16.toCType() == DBusType.uint16.rawValue)
        #expect(DBusType.int32.toCType() == DBusType.int32.rawValue)
        #expect(DBusType.uint32.toCType() == DBusType.uint32.rawValue)
        #expect(DBusType.int64.toCType() == DBusType.int64.rawValue)
        #expect(DBusType.uint64.toCType() == DBusType.uint64.rawValue)
        #expect(DBusType.double.toCType() == DBusType.double.rawValue)
        #expect(DBusType.string.toCType() == DBusType.string.rawValue)
        #expect(DBusType.objectPath.toCType() == DBusType.objectPath.rawValue)
        #expect(DBusType.signature.toCType() == DBusType.signature.rawValue)
        
        // Test container types
        #expect(DBusType.array.toCType() == DBusType.array.rawValue)
        #expect(DBusType.variant.toCType() == DBusType.variant.rawValue)
        #expect(DBusType.struct.toCType() == DBusType.struct.rawValue)
        #expect(DBusType.dictEntry.toCType() == DBusType.dictEntry.rawValue)
        
        // Test invalid type
        #expect(DBusType.invalid.toCType() == DBusType.invalid.rawValue)
    }
    
    /// Tests the conversion from DBusMessageType to C type constants.
    @Test("DBusMessageType To CType")
    func testDBusMessageTypeToCType() throws {
        #expect(DBusMessageType.invalid.toCType() == DBusMessageType.invalid.rawValue)
        #expect(DBusMessageType.methodCall.toCType() == DBusMessageType.methodCall.rawValue)
        #expect(DBusMessageType.methodReturn.toCType() == DBusMessageType.methodReturn.rawValue)
        #expect(DBusMessageType.error.toCType() == DBusMessageType.error.rawValue)
        #expect(DBusMessageType.signal.toCType() == DBusMessageType.signal.rawValue)
    }
}
