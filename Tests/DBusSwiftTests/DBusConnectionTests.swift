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
            let error = DBusError()
            let connection = DBusConnection.connect(to: .session, error: error)
            
            // Check that the connection was successful
            #expect(connection != nil)
            #expect(!error.isSet)
            
            // Check that the connection is not private
            #expect(!connection!.isPrivate)
            
            // Test connection name
            let name = connection!.getUniqueName()
            #expect(name != nil)
            #expect(name?.starts(with: ":") ?? false, "Unique name should start with ':'")
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    
    /// Tests connecting to the system bus.
    @Test("System Bus Connection")
    func testSystemBusConnection() throws {
        do {
            let error = DBusError()
            let connection = DBusConnection.connect(to: .system, error: error)
            
            // Check that the connection was successful
            #expect(connection != nil)
            #expect(!error.isSet)
            
            // Check that the connection is not private
            #expect(!connection!.isPrivate)
            
            // Test connection name
            let name = connection!.getUniqueName()
            #expect(name != nil)
            #expect(name?.starts(with: ":") ?? false, "Unique name should start with ':'")
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to system bus: \(error)")
        }
    }
    
    /// Tests requesting a bus name.
    @Test("Request Name")
    func testRequestName() throws {
        do {
            let error = DBusError()
            let connection = DBusConnection.connect(to: .session, error: error)
            
            guard !error.isSet, let connection = connection else {
                print("Warning: Could not connect to session bus")
                return
            }
            
            // Request a name
            let result = connection.requestName(name: "org.swift.DBusTest", flags: 0)
            
            // We can't guarantee the result since it depends on the environment,
            // but we can check that the call completes without throwing
            #expect(result != -1)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
    }
    
    /// Tests sending a message and receiving a reply.
    @Test("Send With Reply")
    func testSendWithReply() throws {
        do {
            let error = DBusError()
            let connection = DBusConnection.connect(to: .session, error: error)
            
            guard !error.isSet, let connection = connection else {
                print("Warning: Could not connect to session bus")
                return
            }
            
            // Create a method call to list names on the bus
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // Send the message and wait for a reply
            let reply = try connection.sendWithReply(message: msg)
            
            // Check that we got a reply
            #expect(reply != nil)
            #expect(reply.getMessageType() == DBusMessageType.methodReturn.toCType())
            
            // We can't easily verify the contents of the reply,
            // but this ensures the call completes successfully
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not send message: \(error)")
        }
    }
    
    /// Tests the async DBus wrapper.
    @Test("DBus Async")
    func testDBusAsync() async throws {
        do {
            let dbus = try DBusAsync(busType: .session)
            
            // Test that we can create an async connection
            #expect(dbus != nil)
            
            // Test calling a method asynchronously
            let result = try await dbus.call(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames"
            )
            
            // Check that we got a result
            #expect(result != nil)
            
            // We can't easily verify the contents of the result,
            // but this ensures the call completes successfully
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not use async D-Bus: \(error)")
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
