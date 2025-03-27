import Testing
@testable import DBusSwift

#if os(Linux) && canImport(Combine)
import Combine

@Suite("D-Bus Combine Extensions Tests")
struct DBusCombineTests {
    @Test("Test Call Publisher")
    func testCallPublisher() async throws {
        #if os(Linux)
        // Create a cancellable set to store our subscriptions
        var cancellables = Set<AnyCancellable>()
        
        // Create a D-Bus connection
        let dbus = try DBusAsync(busType: .session)
        
        // Create an expectation for the async test
        let expectation = Expectation(description: "Call publisher completes")
        
        // Call ListNames method using the publisher
        dbus.callPublisher(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error: \(error)")
                    #expect(false, "Call publisher failed with error: \(error)")
                }
                expectation.fulfill()
            },
            receiveValue: { value in
                // We should receive an array of bus names
                #expect(!value.isEmpty, "Expected non-empty result from ListNames")
                
                // The result should contain at least the D-Bus service itself
                let stringValues = value.compactMap { $0 as? String }
                #expect(stringValues.contains("org.freedesktop.DBus"), "Result should contain org.freedesktop.DBus")
            }
        )
        .store(in: &cancellables)
        
        // Wait for the expectation to be fulfilled
        try await expectation.fulfill(timeout: .seconds(5))
        #else
        print("Skipping D-Bus Combine tests on non-Linux platform")
        #endif
    }
    
    @Test("Test Signal Publisher")
    func testSignalPublisher() async throws {
        #if os(Linux)
        // This test is more complex as it requires setting up a signal emitter
        // and then listening for the signal with the publisher
        
        // Create a cancellable set to store our subscriptions
        var cancellables = Set<AnyCancellable>()
        
        // Create D-Bus connections for both sending and receiving
        let dbusEmitter = try DBusAsync(busType: .session)
        let dbusReceiver = try DBusAsync(busType: .session)
        
        // Create an expectation for the signal
        let expectation = Expectation(description: "Signal received")
        
        // The test interface and signal name
        let testInterface = "org.swift.DBusTest"
        let testSignal = "TestSignal"
        let testPath = "/org/swift/DBusTest"
        
        // Subscribe to the signal
        dbusReceiver.signalPublisher(interface: testInterface, member: testSignal, path: testPath)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error: \(error)")
                        #expect(false, "Signal publisher failed with error: \(error)")
                    }
                },
                receiveValue: { message in
                    // We received the signal
                    #expect(message.getMessageType() == .signal, "Message should be a signal")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Wait a moment for the subscription to be set up
        try await Task.sleep(for: .milliseconds(500))
        
        // Emit the signal
        Task {
            do {
                let msg = DBusMessage.createSignal(
                    path: testPath,
                    interface: testInterface,
                    name: testSignal
                )
                
                // Get the connection from dbusEmitter
                // This is a bit of a hack since we can't directly access the connection
                // In a real test, we would modify DBusAsync to expose the connection for testing
                let connection = try DBusConnection(busType: .session)
                try connection.send(message: msg)
                
                // Wait a moment to ensure the signal is processed
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                print("Error emitting signal: \(error)")
                #expect(false, "Failed to emit signal: \(error)")
            }
        }
        
        // Wait for the expectation to be fulfilled
        try await expectation.fulfill(timeout: .seconds(5))
        #else
        print("Skipping D-Bus Combine tests on non-Linux platform")
        #endif
    }
}
#else
@Suite("D-Bus Combine Extensions Tests (Skipped)")
struct DBusCombineTests {
    @Test("Skip Combine Tests")
    func testSkipCombineTests() {
        print("Skipping D-Bus Combine tests: requires Linux and Combine support")
    }
}
#endif
