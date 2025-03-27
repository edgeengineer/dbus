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
/// They correspond to the C constants defined in the D-Bus library.

/// Represents an invalid message type.
///
/// Used to indicate an error or uninitialized message.
public let DBUS_MESSAGE_TYPE_INVALID: Int32 = 0

/// Represents a method call message.
///
/// Method calls are sent by clients to servers to invoke methods on objects.
public let DBUS_MESSAGE_TYPE_METHOD_CALL: Int32 = 1

/// Represents a method return message.
///
/// Method returns are sent in response to method calls when the method completes successfully.
public let DBUS_MESSAGE_TYPE_METHOD_RETURN: Int32 = 2

/// Represents an error message.
///
/// Error messages are sent in response to method calls when an error occurs.
public let DBUS_MESSAGE_TYPE_ERROR: Int32 = 3

/// Represents a signal message.
///
/// Signals are broadcast messages that any interested client can receive.
public let DBUS_MESSAGE_TYPE_SIGNAL: Int32 = 4

/// D-Bus bus type constants.
///
/// These constants define the different types of buses available in D-Bus.
/// They correspond to the C constants defined in the D-Bus library.

/// Represents the session bus.
///
/// The session bus is a per-user-login-session bus used for communication between
/// applications that belong to the same user.
public let DBUS_BUS_SESSION: Int32 = 1

/// Represents the system bus.
///
/// The system bus is a system-wide bus used for system-level communication,
/// typically between system services and user applications.
public let DBUS_BUS_SYSTEM: Int32 = 2

/// Represents the starter bus.
///
/// The starter bus is the bus that started the application, which could be
/// either the session bus or the system bus.
public let DBUS_BUS_STARTER: Int32 = 3

/// D-Bus type constants.
///
/// These constants define the different data types used in D-Bus communication.
/// Each constant corresponds to a specific D-Bus type identifier character.
/// The values are the ASCII values of these characters.

/// Represents an invalid type.
public let DBUS_TYPE_INVALID: Int32 = 0

/// Represents an 8-bit unsigned integer (byte).
///
/// Character: 'y', ASCII value: 121
public let DBUS_TYPE_BYTE: Int32 = 121

/// Represents a boolean value.
///
/// Character: 'b', ASCII value: 98
public let DBUS_TYPE_BOOLEAN: Int32 = 98

/// Represents a 16-bit signed integer.
///
/// Character: 'n', ASCII value: 110
public let DBUS_TYPE_INT16: Int32 = 110

/// Represents a 16-bit unsigned integer.
///
/// Character: 'q', ASCII value: 113
public let DBUS_TYPE_UINT16: Int32 = 113

/// Represents a 32-bit signed integer.
///
/// Character: 'i', ASCII value: 105
public let DBUS_TYPE_INT32: Int32 = 105

/// Represents a 32-bit unsigned integer.
///
/// Character: 'u', ASCII value: 117
public let DBUS_TYPE_UINT32: Int32 = 117

/// Represents a 64-bit signed integer.
///
/// Character: 'x', ASCII value: 120
public let DBUS_TYPE_INT64: Int32 = 120

/// Represents a 64-bit unsigned integer.
///
/// Character: 't', ASCII value: 116
public let DBUS_TYPE_UINT64: Int32 = 116

/// Represents a double-precision floating point (IEEE 754).
///
/// Character: 'd', ASCII value: 100
public let DBUS_TYPE_DOUBLE: Int32 = 100

/// Represents a UTF-8 string.
///
/// Character: 's', ASCII value: 115
public let DBUS_TYPE_STRING: Int32 = 115

/// Represents a D-Bus object path.
///
/// Character: 'o', ASCII value: 111
public let DBUS_TYPE_OBJECT_PATH: Int32 = 111

/// Represents a D-Bus type signature.
///
/// Character: 'g', ASCII value: 103
public let DBUS_TYPE_SIGNATURE: Int32 = 103

/// Represents an array of values of a single type.
///
/// Character: 'a', ASCII value: 97
public let DBUS_TYPE_ARRAY: Int32 = 97

/// Represents a value of any type.
///
/// Character: 'v', ASCII value: 118
public let DBUS_TYPE_VARIANT: Int32 = 118

/// Represents a structure containing multiple values of different types.
///
/// Character: 'r', ASCII value: 114
public let DBUS_TYPE_STRUCT: Int32 = 114

/// Represents a dictionary entry (key-value pair).
///
/// Character: 'e', ASCII value: 101
public let DBUS_TYPE_DICT_ENTRY: Int32 = 101

/// Swift wrapper functions for D-Bus C functions.
///
/// These functions provide a more Swift-friendly interface to the underlying
/// C functions in the D-Bus library.

/// Low-level wrapper for the `dbus_bus_get` C function.
///
/// This function connects to a specified D-Bus bus and returns a connection.
///
/// - Parameters:
///   - type: The type of bus to connect to (session, system, or starter).
///   - error: A pointer to a DBusError structure to store error information.
/// - Returns: A pointer to the D-Bus connection, or nil if an error occurs.
@_silgen_name("dbus_bus_get")
public func _dbus_bus_get(_ type: Int32, _ error: UnsafeMutablePointer<CDBus.DBusError>) -> OpaquePointer?

/// Swift wrapper for the `dbus_bus_get` C function.
///
/// This function provides a more Swift-friendly interface to the `dbus_bus_get` C function.
/// It connects to a specified D-Bus bus and returns a connection.
///
/// - Parameters:
///   - type: The type of bus to connect to (session, system, or starter).
///   - error: A pointer to a DBusError structure to store error information.
/// - Returns: A pointer to the D-Bus connection, or nil if an error occurs.
public func swift_dbus_bus_get(type: Int32, error: UnsafeMutablePointer<CDBus.DBusError>) -> OpaquePointer? {
    return _dbus_bus_get(type, error)
}

/// Direct C function call using the original function name.
///
/// This function provides direct access to the `dbus_bus_get` C function.
/// It connects to a specified D-Bus bus and returns a connection.
///
/// - Parameters:
///   - type: The type of bus to connect to (session, system, or starter).
///   - error: A pointer to a DBusError structure to store error information.
/// - Returns: A pointer to the D-Bus connection, or nil if an error occurs.
@_silgen_name("dbus_bus_get")
public func dbus_bus_get_wrapper(_ type: Int32, _ error: UnsafeMutablePointer<CDBus.DBusError>) -> OpaquePointer?
