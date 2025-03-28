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
public typealias DBusBool = dbus_bool_t

/// 32-bit signed integer type used by D-Bus C API.
///
/// Maps to the `dbus_int32_t` type in the D-Bus C library.
public typealias DBusInt32 = Int32

/// 32-bit unsigned integer type used by D-Bus C API.
///
/// Maps to the `dbus_uint32_t` type in the D-Bus C library.
public typealias DBusUInt32 = UInt32

/// D-Bus message type constants.
///
/// These constants define the different types of messages that can be sent over D-Bus.
public enum DBusMessageType: Int32, Equatable, Sendable {
    /// Represents an invalid message type.
    ///
    /// Used to indicate an error or uninitialized message.
    case invalid = 0
    
    /// Represents a method call message.
    ///
    /// Method calls are sent by clients to servers to invoke methods on objects.
    case methodCall = 1
    
    /// Represents a method return message.
    ///
    /// Method returns are sent in response to method calls when the method completes successfully.
    case methodReturn = 2
    
    /// Represents an error message.
    ///
    /// Error messages are sent in response to method calls when an error occurs.
    case error = 3
    
    /// Represents a signal message.
    ///
    /// Signals are sent by servers to notify clients of events.
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
public enum DBusBusType: Int32 {
    /// Represents the session bus.
    ///
    /// The session bus is a per-user-login-session bus used for communication between
    /// applications that belong to the same user.
    case session = 1
    
    /// Represents the system bus.
    ///
    /// The system bus is a system-wide bus used for system-level communication,
    /// typically between system services and user applications.
    case system = 2
    
    /// Represents the starter bus.
    ///
    /// The starter bus is the bus that started the application, which could be
    /// either the session bus or the system bus.
    case starter = 3
}

/// Swift wrapper for D-Bus type constants.
///
/// This enum represents the various data types used in D-Bus communication.
/// Each case corresponds to a specific D-Bus type identifier.
public enum DBusType: Int32, Equatable, Sendable {
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
        return self.rawValue
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
