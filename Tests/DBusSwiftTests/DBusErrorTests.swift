import Testing
@testable import DBusSwift

/// Tests for the DBusError class and error handling functionality.
@Suite("DBusError Tests")
struct DBusErrorTests {
    #if canImport(CDBus)
    /// Tests the basic functionality of the DBusError class.
    @Test("DBusError Basics")
    func testDBusErrorBasics() throws {
        var error = DBusError()
        
        var isSet = error.isSet
        var name = error.name
        var message = error.message
        // Initially, the error should not be set
        #expect(!isSet)
        #expect(name == nil)
        #expect(message == nil)
        
        // Set the error using internal method
        error.setError(name: "org.example.Error.Test", message: "Test error message")
        
        // Check that the error is now set
        isSet = error.isSet
        name = error.name
        message = error.message
        #expect(isSet)
        #expect(name == "org.example.Error.Test")
        #expect(message == "Test error message")
        
        // Clear the error
        error.clear()
        
        // Check that the error is cleared
        isSet = error.isSet
        name = error.name
        message = error.message
        #expect(!isSet)
        #expect(name == nil)
        #expect(message == nil)
    }
    
    /// Tests the clear method of the DBusError class.
    @Test("DBusError Clear")
    func testDBusErrorClear() throws {
        var error = DBusError()
        
        // Set the error
        error.setError(name: "org.example.Error.Test", message: "Test error message")
        var isSet = error.isSet
        #expect(isSet)
        
        // Clear the error
        error.clear()
        
        // Check that the error is cleared
        isSet = error.isSet
        let name = error.name
        let message = error.message
        #expect(!isSet)
        #expect(name == nil)
        #expect(message == nil)
    }
    #endif
}
