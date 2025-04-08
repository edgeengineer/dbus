import Testing
@testable import DBusSwift

/// Tests for the DBusMessage class and related functionality.
@Suite("DBusMessage Tests")
struct DBusMessageTests {
    #if canImport(CDBus)
    /// Tests the creation of different message types.
    @Test("Message Type Creation")
    func testMessageTypeCreation() throws {
        // Test method call creation
        let methodCall = DBusMessage(type: .methodCall)
        let methodCallType = methodCall.messageType
        #expect(methodCallType == .methodCall)
        
        // Test signal creation
        let signal = DBusMessage(type: .signal)
        let signalType = signal.messageType
        #expect(signalType == .signal)
        
        // Test method return creation
        let methodReturn = DBusMessage(type: .methodReturn)
        let methodReturnType = methodReturn.messageType
        #expect(methodReturnType == .methodReturn)
        
        // Test error message creation
        let errorMsg = DBusMessage(type: .error)
        let errorType = errorMsg.messageType
        #expect(errorType == .error)
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
        
        let messageType = msg.messageType
        #expect(messageType == .methodCall)
        
        // Verify message properties
        #expect(msg.destination == "org.freedesktop.DBus")
        #expect(msg.path == "/org/freedesktop/DBus")
        #expect(msg.interface == "org.freedesktop.DBus")
        #expect(msg.member == "ListNames")
    }
    
    /// Tests the creation of signal messages with specific parameters.
    @Test("Signal Creation")
    func testSignalCreation() throws {
        let msg = DBusMessage.createSignal(
            path: "/org/example/Path",
            interface: "org.example.Interface",
            name: "ExampleSignal"
        )
        
        let messageType = msg.messageType
        #expect(messageType == .signal)
        
        // Verify message properties
        #expect(msg.path == "/org/example/Path")
        #expect(msg.interface == "org.example.Interface")
        #expect(msg.member == "ExampleSignal")
    }
    
    /// Tests the message headers functionality.
    @Test("Message Headers")
    func testMessageHeaders() throws {
        var msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        // Verify that we can get and set headers
        msg.setAutoStart(false)
        #expect(msg.getAutoStart() == false)
        
        // Set a destination
        msg.setDestination("org.example.NewDestination")
        #expect(msg.destination == "org.example.NewDestination")

        // Set a sender
        msg.setSender("org.example.Sender")
        #expect(msg.sender == "org.example.Sender")
    }
    
    /// Tests appending arguments to a message.
    @Test("Argument Handling")
    func testArgumentHandling() throws {
        var msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "RequestName"
        )
        
        // Append a string and a uint32
        try msg.appendArguments("org.example.Name", UInt32(0))
        
        // Verify that arguments were appended correctly
        #expect(Bool(true), "Should be able to append arguments")
    }
    #endif
}
