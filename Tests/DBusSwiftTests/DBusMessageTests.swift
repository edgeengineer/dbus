import Testing
@testable import DBusSwift

/// Tests for the DBusMessage class and related functionality.
@Suite("DBusMessage Tests")
struct DBusMessageTests {
    #if os(Linux)
    /// Tests the creation of different message types.
    @Test("Message Type Creation")
    func testMessageTypeCreation() throws {
        // Test method call creation
        let methodCall = DBusMessage(type: .methodCall)
        #expect(methodCall.getMessageType() == DBusMessageType.methodCall.toCType())
        
        // Test signal creation
        let signal = DBusMessage(type: .signal)
        #expect(signal.getMessageType() == DBusMessageType.signal.toCType())
        
        // Test method return creation
        let methodReturn = DBusMessage(type: .methodReturn)
        #expect(methodReturn.getMessageType() == DBusMessageType.methodReturn.toCType())
        
        // Test error message creation
        let errorMsg = DBusMessage(type: .error)
        #expect(errorMsg.getMessageType() == DBusMessageType.error.toCType())
    }
    
    /// Tests the creation of method call messages with specific parameters.
    @Test("Method Call Creation")
    func testMethodCallCreation() throws {
        let msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        #expect(msg.getMessageType() == DBusMessageType.methodCall.toCType())
        #expect(msg.getDestination() == "org.freedesktop.DBus")
        #expect(msg.getPath() == "/org/freedesktop/DBus")
        #expect(msg.getInterface() == "org.freedesktop.DBus")
        #expect(msg.getMember() == "ListNames")
    }
    
    /// Tests the creation of signal messages with specific parameters.
    @Test("Signal Creation")
    func testSignalCreation() throws {
        let msg = DBusMessage.createSignal(
            path: "/org/example/Path",
            interface: "org.example.Interface",
            name: "ExampleSignal"
        )
        
        #expect(msg.getMessageType() == DBusMessageType.signal.toCType())
        #expect(msg.getPath() == "/org/example/Path")
        #expect(msg.getInterface() == "org.example.Interface")
        #expect(msg.getMember() == "ExampleSignal")
    }
    
    /// Tests appending and extracting arguments of various types.
    @Test("Argument Handling")
    func testArgumentHandling() throws {
        let msg = DBusMessage(type: .methodCall)
        
        // Test appending basic types
        try msg.appendArgs(signature: "sibdogu", args: [
            "hello",
            42,
            true,
            3.14,
            "/org/example/Path",
            "sig",
            UInt32(100)
        ])
        
        // Test appending array
        try msg.appendArgs(signature: "as", args: [["string1", "string2", "string3"]])
        
        // We can't easily verify the arguments without a full round-trip test,
        // but this ensures the append calls don't throw
    }
    
    /// Tests setting and getting message headers.
    @Test("Message Headers")
    func testMessageHeaders() throws {
        let msg = DBusMessage(type: .methodCall)
        
        // Set headers
        msg.setDestination("org.example.Destination")
        msg.setPath("/org/example/Path")
        msg.setInterface("org.example.Interface")
        msg.setMember("ExampleMethod")
        msg.setSender("org.example.Sender")
        
        // Verify headers
        #expect(msg.getDestination() == "org.example.Destination")
        #expect(msg.getPath() == "/org/example/Path")
        #expect(msg.getInterface() == "org.example.Interface")
        #expect(msg.getMember() == "ExampleMethod")
        #expect(msg.getSender() == "org.example.Sender")
    }
    #else
    @Test("Skip on Non-Linux")
    func testSkipOnNonLinux() {
        // Skip tests on non-Linux platforms
        print("Skipping D-Bus message tests on non-Linux platform")
    }
    #endif
}
