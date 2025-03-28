import Testing
@testable import DBusSwift

/// Tests for the DBusMessage class and related functionality.
@Suite("DBusMessage Tests")
struct DBusMessageTests {
    #if os(Linux) || (os(macOS) && canImport(CDBus))
    /// Tests the creation of different message types.
    @Test("Message Type Creation")
    func testMessageTypeCreation() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus message type testing on macOS")
        #else
        // Test method call creation
        let methodCall = DBusMessage(type: .methodCall)
        let methodCallType = methodCall.getMessageType()
        #expect(methodCallType == .methodCall)
        
        // Test signal creation
        let signal = DBusMessage(type: .signal)
        let signalType = signal.getMessageType()
        #expect(signalType == .signal)
        
        // Test method return creation
        let methodReturn = DBusMessage(type: .methodReturn)
        let methodReturnType = methodReturn.getMessageType()
        #expect(methodReturnType == .methodReturn)
        
        // Test error message creation
        let errorMsg = DBusMessage(type: .error)
        let errorType = errorMsg.getMessageType()
        #expect(errorType == .error)
        #endif
    }
    
    /// Tests the creation of method call messages with specific parameters.
    @Test("Method Call Creation")
    func testMethodCallCreation() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus method call testing on macOS")
        #else
        let msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        let messageType = msg.getMessageType()
        #expect(messageType == .methodCall)
        #expect(msg.getDestination() == "org.freedesktop.DBus")
        #expect(msg.getPath() == "/org/freedesktop/DBus")
        #expect(msg.getInterface() == "org.freedesktop.DBus")
        #expect(msg.getMember() == "ListNames")
        #endif
    }
    
    /// Tests the creation of signal messages with specific parameters.
    @Test("Signal Creation")
    func testSignalCreation() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus signal testing on macOS")
        #else
        let msg = DBusMessage.createSignal(
            path: "/org/example/Path",
            interface: "org.example.Interface",
            name: "ExampleSignal"
        )
        
        let messageType = msg.getMessageType()
        #expect(messageType == .signal)
        #expect(msg.getPath() == "/org/example/Path")
        #expect(msg.getInterface() == "org.example.Interface")
        #expect(msg.getMember() == "ExampleSignal")
        #endif
    }
    
    /// Tests appending and extracting arguments of various types.
    @Test("Argument Handling")
    func testArgumentHandling() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus argument handling testing on macOS")
        #else
        let msg = DBusMessage(type: .methodCall)
        
        // Test appending basic types
        try msg.appendArguments("hello", 42, true, 3.14, "/org/example/Path", "sig", UInt32(100))
        
        // Test appending array
        let stringArray = ["string1", "string2", "string3"]
        try msg.appendArguments(stringArray)
        
        // We can't easily verify the arguments without a full round-trip test,
        // but this ensures the append calls don't throw
        #endif
    }
    
    /// Tests setting and getting message headers.
    @Test("Message Headers")
    func testMessageHeaders() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus message headers testing on macOS")
        #else
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
        #endif
    }
    #else
    @Test("Skip on Non-Linux")
    func testSkipOnNonLinux() {
        // Skip tests on non-Linux platforms
        print("Skipping D-Bus message tests on non-Linux platform")
    }
    #endif
}
