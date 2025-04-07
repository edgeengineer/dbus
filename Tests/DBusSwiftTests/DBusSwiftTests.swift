import Testing
@testable import DBusSwift

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Tests for general DBusSwift functionality that don't require a running D-Bus daemon
@Suite("DBusSwift Tests")
struct DBusSwiftTests {
    #if canImport(CDBus)
    /// Tests the creation of method call messages
    @Test("Message Creation")
    func testMessageCreation() {
        let msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        // Verify message type using enum comparison
        let messageType = msg.messageType
        #expect(messageType == .methodCall)
        
        // Verify message properties
        #expect(msg.destination == "org.freedesktop.DBus")
        #expect(msg.path == "/org/freedesktop/DBus")
        #expect(msg.interface == "org.freedesktop.DBus")
        #expect(msg.member == "ListNames")
    }
    
    /// Tests the creation of signal messages
    @Test("Signal Creation")
    func testSignalCreation() {
        let msg = DBusMessage.createSignal(
            path: "/org/example/Path",
            interface: "org.example.Interface",
            name: "ExampleSignal"
        )
        
        // Verify message type using enum comparison
        let messageType = msg.messageType
        #expect(messageType == .signal)
        
        // Verify message properties
        #expect(msg.path == "/org/example/Path")
        #expect(msg.interface == "org.example.Interface")
        #expect(msg.member == "ExampleSignal")
    }
    
    /// Tests appending arguments to a message
    @Test("Argument Appending")
    func testArgumentAppending() throws {
        var msg = DBusMessage(type: .methodCall)
        
        try msg.appendArgs(signature: "sib", args: "hello", 42, true)
    }
    
    /// Tests setting and getting message headers
    @Test("Message Headers")
    func testMessageHeaders() {
        var msg = DBusMessage(type: .methodCall)
        
        msg.setDestination("org.example.Destination")
        #expect(msg.destination == "org.example.Destination")
        
        msg.setPath("/org/example/Path")
        #expect(msg.path == "/org/example/Path")
        
        msg.setInterface("org.example.Interface")
        #expect(msg.interface == "org.example.Interface")
        
        msg.setMember("ExampleMethod")
        #expect(msg.member == "ExampleMethod")
        
        msg.setSender("org.example.Sender")
        #expect(msg.sender == "org.example.Sender")
    }
    
    /// Tests creating messages with different types
    @Test("Message Type Creation")
    func testMessageTypeCreation() {
        let methodCall = DBusMessage(type: .methodCall)
        #expect(methodCall.messageType == .methodCall)
        
        let methodReturn = DBusMessage(type: .methodReturn)
        #expect(methodReturn.messageType == .methodReturn)
        
        let error = DBusMessage(type: .error)
        #expect(error.messageType == .error)
        
        let signal = DBusMessage(type: .signal)
        #expect(signal.messageType == .signal)
    }
    
    /// Tests handling various argument types
    @Test("Argument Handling")
    func testArgumentHandling() throws {
        var msg = DBusMessage(type: .methodCall)
        
        try msg.appendArgs(signature: "sidbyx", args:
            "hello",
            Int32(42),
            3.14,
            true,
            UInt8(255),
            Int64(12345)
        )
    }
    
    /// Tests system bus connection
    @Test("System Bus Connection")
    func testSystemBusConnection() throws {
        let _ = try DBusAsync(busType: .system)
    }
    
    /// Tests send with reply functionality
    @Test("Send With Reply")
    func testSendWithReply() async throws {
        let connection = try DBusConnection(busType: .session)
        let msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        // This might fail if D-Bus isn't running, so we'll catch the error
        try await connection.send(message: msg)
    }
    
    /// Tests request name functionality
    @Test("Request Name")
    func testRequestName() async throws {
        let connection = try DBusConnection(busType: .session)
        // Request a unique name that's unlikely to be taken
        let uuid = UUID().uuidString
        let safeName = uuid.replacing("-", with: "")
        let result = try await connection.requestName(name: "org.swift.DBusTest.\(safeName)")
        #expect(result == 1) // DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER
    }
    #endif
}
