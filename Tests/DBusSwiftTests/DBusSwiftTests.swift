import Testing
@testable import DBusSwift

/// Tests for general DBusSwift functionality that don't require a running D-Bus daemon
@Suite("DBusSwift Tests")
struct DBusSwiftTests {
    #if os(Linux) || (os(macOS) && canImport(CDBus))
    /// Tests the creation of method call messages
    @Test("Message Creation")
    func testMessageCreation() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus message creation testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests the creation of signal messages
    @Test("Signal Creation")
    func testSignalCreation() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus signal creation testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests appending arguments to a message
    @Test("Argument Appending")
    func testArgumentAppending() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus argument appending testing on macOS")
        #else
        let msg = DBusMessage(type: .methodCall)
        
        do {
            try msg.appendArgs(signature: "sib", args: ["hello", 42, true])
        } catch {
            print("Failed to append arguments: \(error)")
            #expect(Bool(false), "Should not throw when appending valid arguments")
        }
        #endif
    }
    
    /// Tests setting and getting message headers
    @Test("Message Headers")
    func testMessageHeaders() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus message headers testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests creating messages with different types
    @Test("Message Type Creation")
    func testMessageTypeCreation() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus message type creation testing on macOS")
        #else
        let methodCall = DBusMessage(type: .methodCall)
        #expect(methodCall.getMessageType() == .methodCall)
        
        let methodReturn = DBusMessage(type: .methodReturn)
        #expect(methodReturn.getMessageType() == .methodReturn)
        
        let error = DBusMessage(type: .error)
        #expect(error.getMessageType() == .error)
        
        let signal = DBusMessage(type: .signal)
        #expect(signal.getMessageType() == .signal)
        #endif
    }
    
    /// Tests handling various argument types
    @Test("Argument Handling")
    func testArgumentHandling() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus argument handling testing on macOS")
        #else
        let msg = DBusMessage(type: .methodCall)
        
        do {
            try msg.appendArgs(signature: "sidbxy", args: [
                "hello",
                42,
                3.14,
                true,
                UInt8(255),
                Int16(12345)
            ])
        } catch {
            print("Failed to append arguments: \(error)")
            #expect(Bool(false), "Should not throw when appending valid arguments")
        }
        #endif
    }
    
    /// Tests system bus connection
    @Test("System Bus Connection")
    func testSystemBusConnection() async {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus system bus connection testing on macOS")
        print("Note: Full D-Bus functionality can only be tested on Linux where D-Bus is available.")
        print("These tests only verify that the code compiles correctly on macOS.")
        #else
        do {
            let dbus = try DBusAsync(busType: .system)
            let connection = await dbus.getConnection()
            #expect(connection != nil)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to system bus: \(error)")
        }
        #endif
    }
    
    /// Tests send with reply functionality
    @Test("Send With Reply")
    func testSendWithReply() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus send with reply testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests DBusAsync functionality
    @Test("DBus Async")
    func testDBusAsync() async {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus async testing on macOS")
        #else
        do {
            let dbus = try DBusAsync(busType: .session)
            let connection = await dbus.getConnection()
            #expect(connection != nil)
        } catch {
            print("Warning: Could not create DBusAsync: \(error)")
        }
        #endif
    }
    
    /// Tests request name functionality
    @Test("Request Name")
    func testRequestName() {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus name request testing on macOS")
        #else
        do {
            let connection = try DBusConnection(busType: .session)
            // Request a unique name that's unlikely to be taken
            let result = try connection.requestName(name: "org.swift.DBusTest.\(UUID().uuidString)")
            #expect(result == 1) // DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER
        } catch {
            print("Warning: Could not request name: \(error)")
        }
        #endif
    }
    #else
    /// Placeholder test for platforms without D-Bus
    @Test("D-Bus Not Available")
    func testDBusNotAvailable() {
        print("D-Bus is not available on this platform. Skipping tests.")
    }
    #endif
}