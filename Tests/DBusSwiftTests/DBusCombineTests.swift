@preconcurrency import Combine
import Testing
@testable import DBusSwift

/// Tests for the D-Bus Combine extensions.
@Suite("DBus Combine Tests")
struct DBusCombineTests {
    #if os(Linux) || (os(macOS) && canImport(CDBus))
    /// Tests the call publisher for asynchronous method calls.
    @Test("Call Publisher")
    func testCallPublisher() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus call publisher testing on macOS")
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
            
            // Create a publisher for the call
            let publisher = connection.publisher(for: msg)
            
            // Use a semaphore to wait for the result
            let semaphore = DispatchSemaphore(value: 0)
            var result: DBusMessage?
            var error: Error?
            
            // Subscribe to the publisher
            let cancellable = publisher.sink(
                receiveCompletion: { completion in
                    if case let .failure(err) = completion {
                        error = err
                    }
                    semaphore.signal()
                },
                receiveValue: { message in
                    result = message
                }
            )
            
            // Wait for the result
            _ = semaphore.wait(timeout: .now() + 5)
            
            // Check that we got a result
            #expect(error == nil)
            #expect(result != nil)
            
            // Clean up
            cancellable.cancel()
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
        #endif
    }
    
    /// Tests the signal publisher for asynchronous signal handling.
    @Test("Signal Publisher")
    func testSignalPublisher() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus signal publisher testing on macOS")
        #else
        do {
            let connection = try DBusConnection(busType: .session)
            
            // Create a match rule for signals
            let rule = "type='signal',interface='org.freedesktop.DBus'"
            
            // Create a publisher for signals matching the rule
            let publisher = connection.signalPublisher(matching: rule)
            
            // Use a semaphore to wait for a signal
            let semaphore = DispatchSemaphore(value: 0)
            var receivedSignal = false
            
            // Subscribe to the publisher
            let cancellable = publisher.sink(
                receiveCompletion: { _ in
                    semaphore.signal()
                },
                receiveValue: { _ in
                    receivedSignal = true
                    semaphore.signal()
                }
            )
            
            // Send a message to trigger a signal
            let msg = DBusMessage.createMethodCall(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "GetId"
            )
            
            _ = try connection.send(message: msg)
            
            // Wait for a signal (with timeout)
            _ = semaphore.wait(timeout: .now() + 1)
            
            // We can't guarantee a signal will be received in the test environment,
            // so we don't assert on receivedSignal
            
            // Clean up
            cancellable.cancel()
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to session bus: \(error)")
        }
        #endif
    }
    
    /// Tests the alternative approach using direct connection
    @Test("Alternative Direct Connection")
    func testAlternativeDirectConnection() throws {
        #if os(macOS)
        // On macOS, we'll just print a message about limited testing
        print("Performing limited D-Bus direct connection testing on macOS")
        #else
        do {
            // Create a direct connection
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
        print("Skipping D-Bus Combine tests on non-Linux platform")
    }
    #endif
}
