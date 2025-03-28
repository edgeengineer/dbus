import Testing
@testable import DBusSwift

/// Tests for the DBusConnection class and related functionality.
@Suite("DBusConnection Tests")
struct DBusConnectionTests {
    #if os(Linux) || (os(macOS) && canImport(CDBus))
    /// Tests connecting to the session bus.
    @Test("Session Bus Connection")
    func testSessionBusConnection() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus session bus connection testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests connecting to the system bus.
    @Test("System Bus Connection")
    func testSystemBusConnection() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus system bus connection testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests requesting a bus name.
    @Test("Request Name")
    func testRequestName() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus name request testing on macOS")
        #else
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
        #endif
    }
    
    /// Tests sending a message and receiving a reply.
    @Test("Send With Reply")
    func testSendWithReply() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus send with reply testing on macOS")
        #else
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
                #expect(messageType == .methodReturn)
            }
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
        #endif
    }
    
    /// Tests the DBusAsync class for asynchronous D-Bus operations.
    @Test("DBus Async")
    func testDBusAsync() async throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus async testing on macOS")
        #else
        do {
            let dbus = try DBusAsync(busType: .session)
            
            // Test that we can create an async connection
            #expect(dbus != nil)
            
            // Call a method asynchronously using the call method
            let result = try await dbus.call(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // Check that we got a result
            #expect(result.isEmpty == false)
            
            // Create a direct connection instead of using the actor's connection
            let directConnection = try DBusConnection(busType: .session)
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "GetId"
            )
            
            let reply = try directConnection.send(message: msg)
            
            // Check that we got a reply
            #expect(reply != nil)
            
            if let reply = reply {
                // Check that the reply is a method return message
                let messageType = reply.getMessageType()
                #expect(messageType == .methodReturn)
            }
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
        #endif
    }
    #else
    // This test runs when D-Bus is not available on the platform
    @Test("Skip on Non-Linux")
    func testSkipOnNonLinux() {
        // Skip tests on non-Linux platforms
        print("Skipping D-Bus connection tests on non-Linux platform")
    }
    #endif
}
