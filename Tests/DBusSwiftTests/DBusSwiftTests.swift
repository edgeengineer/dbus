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
        let messageType = msg.getMessageType()
        #expect(messageType == .methodCall)
        
        // Verify message properties
        #expect(msg.getDestination() == "org.freedesktop.DBus")
        #expect(msg.getPath() == "/org/freedesktop/DBus")
        #expect(msg.getInterface() == "org.freedesktop.DBus")
        #expect(msg.getMember() == "ListNames")
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
        let messageType = msg.getMessageType()
        #expect(messageType == .signal)
        
        // Verify message properties
        #expect(msg.getPath() == "/org/example/Path")
        #expect(msg.getInterface() == "org.example.Interface")
        #expect(msg.getMember() == "ExampleSignal")
    }
    
    /// Tests appending arguments to a message
    @Test("Argument Appending")
    func testArgumentAppending() {
        let msg = DBusMessage(type: .methodCall)
        
        do {
            try msg.appendArgs(signature: "sib", args: ["hello", 42, true])
        } catch {
            print("Failed to append arguments: \(error)")
            #expect(Bool(false), "Should not throw when appending valid arguments")
        }
    }
    
    /// Tests setting and getting message headers
    @Test("Message Headers")
    func testMessageHeaders() {
        let msg = DBusMessage(type: .methodCall)
        
        msg.setDestination("org.example.Destination")
        #expect(msg.getDestination() == "org.example.Destination")
        
        msg.setPath("/org/example/Path")
        #expect(msg.getPath() == "/org/example/Path")
        
        msg.setInterface("org.example.Interface")
        #expect(msg.getInterface() == "org.example.Interface")
        
        msg.setMember("ExampleMethod")
        #expect(msg.getMember() == "ExampleMethod")
        
        msg.setSender("org.example.Sender")
        #expect(msg.getSender() == "org.example.Sender")
    }
    
    /// Tests creating messages with different types
    @Test("Message Type Creation")
    func testMessageTypeCreation() {
        let methodCall = DBusMessage(type: .methodCall)
        #expect(methodCall.getMessageType() == .methodCall)
        
        let methodReturn = DBusMessage(type: .methodReturn)
        #expect(methodReturn.getMessageType() == .methodReturn)
        
        let error = DBusMessage(type: .error)
        #expect(error.getMessageType() == .error)
        
        let signal = DBusMessage(type: .signal)
        #expect(signal.getMessageType() == .signal)
    }
    
    /// Tests handling various argument types
    @Test("Argument Handling")
    func testArgumentHandling() {
        let msg = DBusMessage(type: .methodCall)
        
        do {
            try msg.appendArgs(signature: "sidbyx", args: [
                "hello",
                Int32(42),
                3.14,
                true,
                UInt8(255),
                Int64(12345)
            ])
        } catch {
            print("Failed to append arguments: \(error)")
            #expect(Bool(false), "Should not throw when appending valid arguments")
        }
    }
    
    /// Tests system bus connection
    @Test("System Bus Connection")
    func testSystemBusConnection() async {
        do {
            let dbus = try DBusAsync(busType: .system)
            let _ = await dbus.getConnection()
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to system bus: \(error)")
        }
    }
    
    /// Tests send with reply functionality
    @Test("Send With Reply")
    func testSendWithReply() {
        do {
            let connection = try DBusConnection(busType: .session)
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // This might fail if D-Bus isn't running, so we'll catch the error
            _ = try? connection.send(message: msg)
        } catch {
            print("Warning: Could not send message: \(error)")
        }
    }
    
    /// Tests DBusAsync functionality
    @Test("DBus Async")
    func testDBusAsync() async {
        do {
            let dbus = try DBusAsync(busType: .session)
            let _ = await dbus.getConnection()
        } catch {
            print("Warning: Could not create DBusAsync: \(error)")
        }
    }
    
    /// Tests request name functionality
    @Test("Request Name")
    func testRequestName() {
        do {
            let connection = try DBusConnection(busType: .session)
            // Request a unique name that's unlikely to be taken
            let uuid = UUID().uuidString
            let safeName = uuid.replacing("-", with: "_")
            let result = try connection.requestName(name: "org.swift.DBusTest.\(safeName)")
            #expect(result == 1) // DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER
        } catch {
            print("Warning: Could not request name: \(error)")
        }
    }
    #endif
}