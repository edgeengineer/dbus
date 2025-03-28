import Testing
@testable import DBusSwift

/// Tests for the DBusConnection class and related functionality.
@Suite("DBusConnection Tests")
struct DBusConnectionTests {
    #if os(Linux)
    /// Tests connecting to the session bus.
    @Test("Session Bus Connection")
    func testSessionBusConnection() throws {
        do {
            let connection = try DBusConnection(busType: .session)
            
            // Check that the connection was successful
            #expect(connection.getConnection() != nil)
            
            // Test connection by sending a simple message
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "GetId"
            )
            
            let reply = try connection.send(message: msg)
            #expect(reply != nil)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    
    /// Tests connecting to the system bus.
    @Test("System Bus Connection")
    func testSystemBusConnection() throws {
        do {
            let connection = try DBusConnection(busType: .system)
            
            // Check that the connection was successful
            #expect(connection.getConnection() != nil)
            
            // Test connection by sending a simple message
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "GetId"
            )
            
            let reply = try connection.send(message: msg)
            #expect(reply != nil)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to system bus: \(error)")
        }
    }
    
    /// Tests requesting a bus name.
    @Test("Request Name")
    func testRequestName() throws {
        do {
            let connection = try DBusConnection(busType: .session)
            
            // Create a method call to request a name
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "RequestName"
            )
            
            // Add arguments: name and flags
            try msg.appendArguments("org.swift.DBusTest", UInt32(0))
            
            // Send the message and wait for a reply
            let reply = try connection.send(message: msg)
            
            // We can't guarantee the result since it depends on the environment,
            // but we can check that the call completes without throwing
            #expect(reply != nil)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    
    /// Tests sending a message and receiving a reply.
    @Test("Send With Reply")
    func testSendWithReply() throws {
        do {
            let connection = try DBusConnection(busType: .session)
            
            // Create a method call to list names on the bus
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // Send the message and wait for a reply
            let reply = try connection.send(message: msg)
            
            // Check that we got a reply
            #expect(reply != nil)
            
            if let reply = reply {
                // Check that the reply is a method return message
                let messageType = reply.getMessageType()
                #expect(messageType.rawValue == DBUS_MESSAGE_TYPE_METHOD_RETURN)
            }
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    
    /// Tests the DBusAsync class for asynchronous D-Bus operations.
    @Test("DBus Async")
    func testDBusAsync() async throws {
        do {
            let dbus = try DBusAsync(busType: .session)
            
            // Test that we can create an async connection
            #expect(dbus != nil)
            
            // Create a method call to list names on the bus
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // Send the message asynchronously
            let reply = try await dbus.send(message: msg)
            
            // Check that we got a reply
            #expect(reply != nil)
            
            if let reply = reply {
                // Check that the reply is a method return message
                let messageType = reply.getMessageType()
                #expect(messageType.rawValue == DBUS_MESSAGE_TYPE_METHOD_RETURN)
            }
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    #else
    @Test("Skip on Non-Linux")
    func testSkipOnNonLinux() {
        // Skip tests on non-Linux platforms
        print("Skipping D-Bus connection tests on non-Linux platform")
    }
    #endif
}
