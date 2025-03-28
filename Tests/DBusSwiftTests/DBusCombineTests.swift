import Testing
@testable import DBusSwift

#if (os(Linux) || os(macOS)) && canImport(Combine) && canImport(CDBus)
import Combine

@Suite("D-Bus Combine Extensions Tests")
struct DBusCombineTests {
    @Test("Test Call Publisher")
    func testCallPublisher() async throws {
        // Create a cancellable set to store our subscriptions
        var cancellables = Set<AnyCancellable>()
        
        // Create a D-Bus connection
        let dbus = try DBusAsync(busType: .session)
        
        // Use a simple async flag instead of Expectation
        var completed = false
        var receivedValue = false
        
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
                    completed = true
                case .failure(let error):
                    print("Error: \(error)")
                    #expect(false, "Call publisher failed with error: \(error)")
                }
            },
            receiveValue: { value in
                // We should receive an array of bus names
                #expect(!value.isEmpty, "Expected non-empty result from ListNames")
                
                // The result should contain at least the D-Bus service itself
                let stringValues = value.compactMap { $0 as? String }
                #expect(stringValues.contains("org.freedesktop.DBus"), "Result should contain org.freedesktop.DBus")
                receivedValue = true
            }
        )
        .store(in: &cancellables)
        
        // Wait for a short time to allow the publisher to complete
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Check that we received a value and completed
        #expect(receivedValue, "Should have received a value")
        #expect(completed, "Publisher should have completed")
    }
    
    @Test("Test Signal Publisher")
    func testSignalPublisher() async throws {
        // This test is more complex as it requires setting up a signal emitter
        // and then listening for the signal with the publisher
        
        // Create a cancellable set to store our subscriptions
        var cancellables = Set<AnyCancellable>()
        
        // Create D-Bus connections for both sending and receiving
        let dbusEmitter = try DBusAsync(busType: .session)
        let dbusReceiver = try DBusAsync(busType: .session)
        
        // Use a simple async flag instead of Expectation
        var signalReceived = false
        
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
                    let messageType = message.getMessageType()
                    #expect(messageType.rawValue == DBUS_MESSAGE_TYPE_SIGNAL, "Message should be a signal")
                    signalReceived = true
                }
            )
            .store(in: &cancellables)
        
        // Wait a moment for the subscription to be set up
        try await Task.sleep(nanoseconds: 500_000_000) // 500 milliseconds
        
        // Emit the signal using the emitSignal method
        try await dbusEmitter.emitSignal(
            path: testPath,
            interface: testInterface,
            name: testSignal
        )
        
        // Wait for a short time to allow the signal to be received
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Check that we received the signal
        #expect(signalReceived, "Should have received the signal")
    }
}
#else
@Suite("D-Bus Combine Extensions Tests (Skipped)")
struct DBusCombineTests {
    @Test("Skip Combine Tests")
    func testSkipCombineTests() {
        print("Skipping D-Bus Combine tests: requires Linux/macOS with D-Bus and Combine support")
    }
}
#endif
