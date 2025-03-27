import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Examples of using DBusSwift
public enum DBusExamples {
    /// Example of calling a method on the system bus
    /// - Note: This is just for demonstration and will not be compiled into the library
    public static func listSystemServicesExample() async -> Void {
        do {
            // Create a D-Bus connection to the system bus
            let dbus = try DBusAsync(busType: .system)
            
            // Call the ListNames method on the D-Bus service
            let result = try await dbus.callMethod(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "ListNames",
                args: [] as [any Sendable],
                signature: "",
                replySignature: "as"
            )
            
            // The result is an array of Any type, but we know it's an array of strings
            if let services = result.first as? [String] {
                print("Available D-Bus services:")
                for service in services {
                    print("- \(service)")
                }
            }
        } catch {
            print("D-Bus error: \(error)")
        }
    }
    
    /// Example of emitting a signal
    public static func emitSignalExample() async -> Void {
        do {
            // Create a D-Bus connection to the session bus
            let dbus = try DBusAsync(busType: .session)
            
            // Emit a signal
            try await dbus.emitSignal(
                path: "/org/example/Path",
                interface: "org.example.Interface",
                name: "ExampleSignal",
                args: ["Hello from Swift!", 42] as [any Sendable],
                signature: "si"
            )
            
            print("Signal emitted successfully")
        } catch {
            print("D-Bus error: \(error)")
        }
    }
    
    /// Example of calling a method with arguments and receiving a reply
    public static func callMethodWithArgsExample() async -> Void {
        do {
            // Create a D-Bus connection to the session bus
            let dbus = try DBusAsync(busType: .session)
            
            // Call GetConnectionUnixProcessID to get the PID of a connection
            let result = try await dbus.callMethod(
                destination: "org.freedesktop.DBus",
                path: "/org/freedesktop/DBus",
                interface: "org.freedesktop.DBus",
                method: "GetConnectionUnixProcessID",
                args: ["org.freedesktop.DBus"] as [any Sendable],
                signature: "s",
                replySignature: "u"
            )
            
            if let pid = result.first as? UInt32 {
                print("The D-Bus daemon's PID is: \(pid)")
            }
        } catch {
            print("D-Bus error: \(error)")
        }
    }
}