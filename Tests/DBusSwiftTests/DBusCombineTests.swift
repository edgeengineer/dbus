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
                    let messageType = message.getMessageType()
                    #expect(messageType.rawValue == DBUS_MESSAGE_TYPE_SIGNAL, "Message should be a signal")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Wait a moment for the subscription to be set up
        try await Task.sleep(for: .milliseconds(500))
        
        // Emit the signal
        let signal = DBusMessage.createSignal(path: testPath, interface: testInterface, name: testSignal)
        try dbusEmitter.send(message: signal)
        
        // Wait for the expectation to be fulfilled
        try await expectation.fulfill(timeout: .seconds(5))
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
