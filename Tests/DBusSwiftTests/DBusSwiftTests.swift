import Testing
@testable import DBusSwift

@Suite("DBusSwift Tests")
struct DBusSwiftTests {
    @Test("Message Creation")
    func testMessageCreation() throws {
        #if os(Linux)
        let msg = DBusMessage.createMethodCall(
            destination: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            interface: "org.freedesktop.DBus",
            method: "ListNames"
        )
        
        #expect(msg.getMessageType() == .methodCall)
        #else
        // Skip test on non-Linux platforms
        print("Skipping D-Bus tests on non-Linux platform")
        #endif
    }
    
    @Test("Signal Creation")
    func testSignalCreation() throws {
        #if os(Linux)
        let msg = DBusMessage.createSignal(
            path: "/org/example/Path",
            interface: "org.example.Interface",
            name: "ExampleSignal"
        )
        
        let messageType = msg.getMessageType()
        #expect(messageType == .signal)
        #else
        // Skip test on non-Linux platforms
        print("Skipping D-Bus tests on non-Linux platform")
        #endif
    }
    
    @Test("Argument Appending")
    func testArgumentAppending() throws {
        #if os(Linux)
        let msg = DBusMessage(type: .methodCall)
        
        try msg.appendArgs(signature: "sib", args: ["hello", 42, true])
        
        // We can't easily verify the arguments, but this test ensures the call doesn't throw
        #else
        // Skip test on non-Linux platforms
        print("Skipping D-Bus tests on non-Linux platform")
        #endif
    }
    
    #if os(Linux)
    // Only run this test on Linux with D-Bus installed
    @Test("System Bus Connection")
    func testSystemBusConnection() async throws {
        do {
            let dbus = try DBusAsync(busType: .system)
            // Just testing that we can create a connection without throwing
            #expect(dbus != nil)
        } catch {
            // Allow failure if D-Bus isn't running
            print("Warning: Could not connect to system bus: \(error)")
        }
    }
    #endif
}