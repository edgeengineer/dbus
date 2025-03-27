import Testing
@testable import DBusSwift

/// Tests for the DBusError class and error handling functionality.
@Suite("DBusError Tests")
struct DBusErrorTests {
    /// Tests the basic functionality of the DBusError class.
    @Test("DBusError Basics")
    func testDBusErrorBasics() throws {
        let error = DBusError()
        
        // Initially, the error should not be set
        #expect(!error.isSet)
        #expect(error.name == nil)
        #expect(error.message == nil)
        
        // Set the error using internal method
        error.setError(name: "org.example.Error.Test", message: "Test error message")
        
        // Check that the error is now set
        #expect(error.isSet)
        #expect(error.name == "org.example.Error.Test")
        #expect(error.message == "Test error message")
        
        // Free the error
        error.free()
        
        // Check that the error is cleared
        #expect(!error.isSet)
        #expect(error.name == nil)
        #expect(error.message == nil)
    }
    
    /// Tests the clearError method of the DBusError class.
    @Test("DBusError Clear")
    func testDBusErrorClear() throws {
        let error = DBusError()
        
        // Set the error
        error.setError(name: "org.example.Error.Test", message: "Test error message")
        #expect(error.isSet)
        
        // Clear the error
        error.clearError()
        
        // Check that the error is cleared
        #expect(!error.isSet)
        #expect(error.name == nil)
        #expect(error.message == nil)
    }
}
