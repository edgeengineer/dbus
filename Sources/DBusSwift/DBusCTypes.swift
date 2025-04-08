import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Swift type aliases for D-Bus C types.
///
/// These type aliases provide a more Swift-friendly interface to the underlying
/// C types used by the D-Bus library. Using these types helps maintain
/// consistency and clarity when working with D-Bus API.

/// Boolean type used by D-Bus C API.
///
/// Maps to the `dbus_bool_t` type in the D-Bus C library.
internal typealias DBusBool = dbus_bool_t

/// 32-bit signed integer type used by D-Bus C API.
///
/// Maps to the `dbus_int32_t` type in the D-Bus C library.
internal typealias DBusInt32 = Int32

/// 32-bit unsigned integer type used by D-Bus C API.
///
/// Maps to the `dbus_uint32_t` type in the D-Bus C library.
internal typealias DBusUInt32 = UInt32

/// D-Bus message type constants.
///
/// These constants define the different types of messages that can be sent over D-Bus.
/// D-Bus is a message bus system that allows applications to communicate with one another.
/// It uses a binary protocol for efficient message passing between processes.
///
/// Message types are fundamental to D-Bus communication, as they determine how a message
/// is handled by the bus and receiving applications. Each message type serves a specific
/// purpose in the D-Bus communication model:
///
/// - Method calls initiate requests to objects
/// - Method returns provide successful responses
/// - Error messages indicate failures
/// - Signals broadcast events to interested listeners
///
/// Understanding these message types is essential for properly implementing D-Bus
/// communication in your application.
public enum DBusMessageType: Int32, Equatable, Sendable {
    /// Represents an invalid message type.
    ///
    /// Used to indicate an error or uninitialized message.
    /// Messages with this type should not be sent on the bus and typically
    /// indicate a programming error if encountered.
    case invalid = 0
    
    /// Represents a method call message.
    ///
    /// Method calls are sent by clients to servers to invoke methods on objects.
    /// They contain a destination, path, interface, and method name, along with
    /// any arguments required by the method. Method calls typically expect a
    /// response in the form of a method return or error message.
    ///
    /// Example: A client application calling the `ListNames` method on the
    /// D-Bus name service to get a list of available services.
    case methodCall = 1
    
    /// Represents a method return message.
    ///
    /// Method returns are sent in response to method calls when the method completes successfully.
    /// They contain any return values from the method. Each method return corresponds to
    /// a specific method call and includes a reference to the serial number of that call.
    ///
    /// Example: The D-Bus name service responding to a `ListNames` call with
    /// an array of available service names.
    case methodReturn = 2
    
    /// Represents an error message.
    ///
    /// Error messages are sent in response to method calls when an error occurs.
    /// They contain an error name, a human-readable error message, and possibly
    /// additional error details. Like method returns, each error message corresponds
    /// to a specific method call and includes a reference to the serial number of that call.
    ///
    /// Example: The D-Bus name service responding with an "AccessDenied" error
    /// when a client tries to call a method it doesn't have permission to use.
    case error = 3
    
    /// Represents a signal message.
    ///
    /// Signals are sent by servers to notify clients of events.
    /// Unlike method calls, signals do not expect a response. They are broadcast
    /// to all interested clients that have registered to receive them. Signals
    /// contain a path, interface, and signal name, along with any data associated
    /// with the event.
    ///
    /// Example: A battery service broadcasting a "LowBattery" signal when the
    /// system's battery level drops below a certain threshold.
    case signal = 4
    
    /// Returns the C type constant for this message type.
    ///
    /// - Returns: The corresponding C type constant.
    internal func toCType() -> Int32 {
        return self.rawValue
    }
}

/// D-Bus bus type constants.
///
/// These constants define the different types of buses available in D-Bus.
/// D-Bus typically provides several standard buses, each serving a different purpose
/// in the system's communication architecture. The bus type determines the scope and
/// security context of the communication.
///
/// D-Bus buses act as message routers that deliver messages between applications.
/// Each bus type has different security properties, visibility, and intended use cases:
///
/// - The system bus connects system services and privileged applications
/// - The session bus connects user applications within a login session
/// - The starter bus is a special bus created by the application that started the message bus
///
/// Applications connect to these buses to communicate with other applications or
/// system services in a standardized way.
public enum DBusBusType: Int32, Sendable {
    /// Represents the session-specific D-Bus bus.
    ///
    /// The session bus is specific to a user login session and is used for communication
    /// between user applications. Each user session has its own session bus instance,
    /// providing isolation between different users.
    ///
    /// The session bus is typically used for:
    /// - Desktop integration
    /// - Application-to-application communication
    /// - User notifications
    /// - Session management
    ///
    /// The session bus is accessible to all applications running in the user's session.
    case session = 0
    
    /// Represents the system-wide D-Bus bus.
    ///
    /// The system bus is a global bus that spans the entire system and is typically
    /// used by system services and privileged applications. It is persistent across
    /// user sessions and provides access to system-level functionality.
    ///
    /// The system bus is typically used for:
    /// - Hardware management (power, network, bluetooth)
    /// - System configuration
    /// - Security services
    /// - System-wide notifications
    ///
    /// Access to services on the system bus is typically restricted by security policies.
    case system = 1
    
    /// Represents the bus that started the connection.
    ///
    /// The starter bus is a special case that refers to the bus that the application
    /// was launched from. This is useful for applications that can be launched from
    /// either the system or session bus and need to communicate back to the launching bus.
    ///
    /// This is less commonly used than the system and session buses, but provides
    /// flexibility for applications that can operate in multiple contexts.
    case starter = 2
}

/// Swift wrapper for D-Bus type constants.
///
/// This enum represents the various data types used in D-Bus communication.
/// Each case corresponds to a specific D-Bus type identifier.
public enum DBusType: Int8, Equatable, Sendable {
    /// Represents an invalid type.
    case invalid = 0
    
    /// Represents an 8-bit unsigned integer (byte).
    ///
    /// Character: 'y', ASCII value: 121
    case byte = 121
    
    /// Represents a boolean value (true or false).
    ///
    /// Character: 'b', ASCII value: 98
    case boolean = 98
    
    /// Represents a 16-bit signed integer.
    ///
    /// Character: 'n', ASCII value: 110
    case int16 = 110
    
    /// Represents a 16-bit unsigned integer.
    ///
    /// Character: 'q', ASCII value: 113
    case uint16 = 113
    
    /// Represents a 32-bit signed integer.
    ///
    /// Character: 'i', ASCII value: 105
    case int32 = 105
    
    /// Represents a 32-bit unsigned integer.
    ///
    /// Character: 'u', ASCII value: 117
    case uint32 = 117
    
    /// Represents a 64-bit signed integer.
    ///
    /// Character: 'x', ASCII value: 120
    case int64 = 120
    
    /// Represents a 64-bit unsigned integer.
    ///
    /// Character: 't', ASCII value: 116
    case uint64 = 116
    
    /// Represents a double-precision floating point number.
    ///
    /// Character: 'd', ASCII value: 100
    case double = 100
    
    /// Represents a UTF-8 string.
    ///
    /// Character: 's', ASCII value: 115
    case string = 115
    
    /// Represents a D-Bus object path.
    ///
    /// Character: 'o', ASCII value: 111
    case objectPath = 111
    
    /// Represents a D-Bus type signature.
    ///
    /// Character: 'g', ASCII value: 103
    case signature = 103
    
    /// Represents a Unix file descriptor.
    ///
    /// Character: 'h', ASCII value: 104
    case unixFd = 104
    
    /// Represents an array of values of the same type.
    ///
    /// Character: 'a', ASCII value: 97
    case array = 97
    
    /// Represents a value of any type.
    ///
    /// Character: 'v', ASCII value: 118
    case variant = 118
    
    /// Represents a structure containing values of different types.
    ///
    /// Character: 'r', ASCII value: 114
    case `struct` = 114
    
    /// Represents a dictionary entry (key-value pair).
    ///
    /// Character: 'e', ASCII value: 101
    case dictEntry = 101

    init?(rawValue: Int32) {
        guard 
            rawValue >= 0,
            rawValue <= 127,
            let type = DBusType(rawValue: Int8(rawValue)) 
        else {
            return nil
        }
        self = type
    }
    
    /// Initialize with a string value
    ///
    /// - Parameter stringValue: A single character string representing a D-Bus type.
    public init?(stringValue: String) {
        guard let type = DBusType.fromString(stringValue) else {
            return nil
        }
        self = type
    }
    
    /// Returns the string representation of this D-Bus type.
    ///
    /// - Returns: A single character string representing this D-Bus type.
    public func stringValue() -> String {
        switch self {
        case .byte: return "y"
        case .boolean: return "b"
        case .int16: return "n"
        case .uint16: return "q"
        case .int32: return "i"
        case .uint32: return "u"
        case .int64: return "x"
        case .uint64: return "t"
        case .double: return "d"
        case .string: return "s"
        case .objectPath: return "o"
        case .signature: return "g"
        case .array: return "a"
        case .variant: return "v"
        case .struct: return "r"
        case .dictEntry: return "e"
        case .unixFd: return "h"
        case .invalid: return ""
        }
    }
    
    /// Returns the C type constant for this D-Bus type.
    ///
    /// - Returns: The corresponding C type constant.
    internal func toCType() -> Int32 {
        return Int32(self.rawValue)
    }
    
    /// Initializes a D-Bus type from its string representation.
    ///
    /// - Parameter stringValue: A single character string representing a D-Bus type.
    /// - Returns: The corresponding D-Bus type, or nil if the string doesn't represent a valid type.
    public static func fromString(_ stringValue: String) -> DBusType? {
        guard stringValue.count == 1, let firstChar = stringValue.first else {
            return nil
        }
        
        switch firstChar {
        case "y": return .byte
        case "b": return .boolean
        case "n": return .int16
        case "q": return .uint16
        case "i": return .int32
        case "u": return .uint32
        case "x": return .int64
        case "t": return .uint64
        case "d": return .double
        case "s": return .string
        case "o": return .objectPath
        case "g": return .signature
        case "a": return .array
        case "v": return .variant
        case "r": return .struct
        case "e": return .dictEntry
        case "h": return .unixFd
        default: return nil
        }
    }
}

/// Low-level wrapper for the `dbus_bus_get` C function.
///
/// This function connects to a specified D-Bus bus and returns a connection.
///
/// - Parameters:
///   - type: The type of bus to connect to (session, system, or starter).
///   - error: A pointer to a DBusError structure to store error information.
/// - Returns: A pointer to the D-Bus connection, or nil if an error occurs.
@_silgen_name("dbus_bus_get")
internal func _dbus_bus_get(_ type: Int32, _ error: UnsafeMutablePointer<CDBus.DBusError>) -> OpaquePointer?
