import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Swift wrapper for D-Bus type constants.
///
/// This enumeration represents the various data types used in D-Bus communication.
/// Each case corresponds to a specific D-Bus type identifier character.
///
/// D-Bus uses a type system to describe the data being transferred between applications.
/// These types are represented as single ASCII characters in D-Bus signatures.
///
/// - Note: The raw values of these enum cases match the ASCII values of the D-Bus type characters.
///
/// ## Basic Types
/// - `byte`: 8-bit unsigned integer
/// - `boolean`: Boolean value (true or false)
/// - `int16`: 16-bit signed integer
/// - `uint16`: 16-bit unsigned integer
/// - `int32`: 32-bit signed integer
/// - `uint32`: 32-bit unsigned integer
/// - `int64`: 64-bit signed integer
/// - `uint64`: 64-bit unsigned integer
/// - `double`: Double-precision floating point (IEEE 754)
/// - `string`: UTF-8 string
/// - `objectPath`: D-Bus object path
/// - `signature`: D-Bus type signature
/// - `invalid`: Invalid type
///
/// ## Container Types
/// - `array`: Array of values of a single type
/// - `variant`: Value of any type
/// - `struct`: Structure containing multiple values of different types
/// - `dictEntry`: Dictionary entry (key-value pair)
///
/// ## Usage Examples
///
/// ### Converting between enum values and string representations
///
/// ```swift
/// // Get the string representation of a type
/// let typeChar = DBusType.string.stringValue()  // Returns "s"
///
/// // Create a type from its string representation
/// if let type = DBusType(stringValue: "i") {
///     // type is DBusType.int32
/// }
/// ```
///
/// ### Creating D-Bus signatures
///
/// ```swift
/// // A signature for an array of strings
/// let signature = DBusType.arrayAsString + DBusType.stringAsString  // "as"
///
/// // A signature for a dictionary mapping strings to variants
/// let dictSignature = DBusType.arrayAsString +
///                    "{" + DBusType.stringAsString + DBusType.variantAsString + "}"  // "a{sv}"
/// ```
public enum DBusType: Int32 {
    /// 8-bit unsigned integer ('y')
    case byte = 121
    
    /// Boolean value (true or false) ('b')
    case boolean = 98
    
    /// 16-bit signed integer ('n')
    case int16 = 110
    
    /// 16-bit unsigned integer ('q')
    case uint16 = 113
    
    /// 32-bit signed integer ('i')
    case int32 = 105
    
    /// 32-bit unsigned integer ('u')
    case uint32 = 117
    
    /// 64-bit signed integer ('x')
    case int64 = 120
    
    /// 64-bit unsigned integer ('t')
    case uint64 = 116
    
    /// Double-precision floating point (IEEE 754) ('d')
    case double = 100
    
    /// UTF-8 string ('s')
    case string = 115
    
    /// D-Bus object path ('o')
    case objectPath = 111
    
    /// D-Bus type signature ('g')
    case signature = 103
    
    /// Invalid type ('\0')
    case invalid = 0
    
    // Container types
    
    /// Array of values of a single type ('a')
    case array = 97
    
    /// Value of any type ('v')
    case variant = 118
    
    /// Structure containing multiple values of different types ('r')
    case `struct` = 114
    
    /// Dictionary entry (key-value pair) ('e')
    case dictEntry = 101
    
    // Type string constants
    
    /// String representation of the byte type: "y"
    public static let byteAsString = "y"
    
    /// String representation of the boolean type: "b"
    public static let booleanAsString = "b"
    
    /// String representation of the int16 type: "n"
    public static let int16AsString = "n"
    
    /// String representation of the uint16 type: "q"
    public static let uint16AsString = "q"
    
    /// String representation of the int32 type: "i"
    public static let int32AsString = "i"
    
    /// String representation of the uint32 type: "u"
    public static let uint32AsString = "u"
    
    /// String representation of the int64 type: "x"
    public static let int64AsString = "x"
    
    /// String representation of the uint64 type: "t"
    public static let uint64AsString = "t"
    
    /// String representation of the double type: "d"
    public static let doubleAsString = "d"
    
    /// String representation of the string type: "s"
    public static let stringAsString = "s"
    
    /// String representation of the object path type: "o"
    public static let objectPathAsString = "o"
    
    /// String representation of the signature type: "g"
    public static let signatureAsString = "g"
    
    /// String representation of the array type: "a"
    public static let arrayAsString = "a"
    
    /// String representation of the variant type: "v"
    public static let variantAsString = "v"
    
    /// String representation of the struct type: "r"
    public static let structAsString = "r"
    
    /// String representation of the dictionary entry type: "e"
    public static let dictEntryAsString = "e"
    
    /// Returns the string representation of this type.
    ///
    /// This method returns the single-character string that represents this D-Bus type
    /// in a D-Bus signature.
    ///
    /// - Returns: A string containing a single character representing this type.
    public func stringValue() -> String {
        switch self {
        case .byte:
            return DBusType.byteAsString
        case .boolean:
            return DBusType.booleanAsString
        case .int16:
            return DBusType.int16AsString
        case .uint16:
            return DBusType.uint16AsString
        case .int32:
            return DBusType.int32AsString
        case .uint32:
            return DBusType.uint32AsString
        case .int64:
            return DBusType.int64AsString
        case .uint64:
            return DBusType.uint64AsString
        case .double:
            return DBusType.doubleAsString
        case .string:
            return DBusType.stringAsString
        case .objectPath:
            return DBusType.objectPathAsString
        case .signature:
            return DBusType.signatureAsString
        case .array:
            return DBusType.arrayAsString
        case .variant:
            return DBusType.variantAsString
        case .struct:
            return DBusType.structAsString
        case .dictEntry:
            return DBusType.dictEntryAsString
        case .invalid:
            return ""
        }
    }
    
    /// Creates a DBusType from its string representation.
    ///
    /// This initializer takes a single-character string that represents a D-Bus type
    /// in a D-Bus signature and returns the corresponding DBusType.
    ///
    /// - Parameter stringValue: A string containing a single character representing a D-Bus type.
    /// - Returns: The corresponding DBusType, or nil if the string does not represent a valid D-Bus type.
    public init?(stringValue: String) {
        guard stringValue.count == 1, let firstChar = stringValue.first else {
            return nil
        }
        
        let asciiValue = Int32(firstChar.asciiValue ?? 0)
        
        switch asciiValue {
        case DBusType.byte.rawValue:
            self = .byte
        case DBusType.boolean.rawValue:
            self = .boolean
        case DBusType.int16.rawValue:
            self = .int16
        case DBusType.uint16.rawValue:
            self = .uint16
        case DBusType.int32.rawValue:
            self = .int32
        case DBusType.uint32.rawValue:
            self = .uint32
        case DBusType.int64.rawValue:
            self = .int64
        case DBusType.uint64.rawValue:
            self = .uint64
        case DBusType.double.rawValue:
            self = .double
        case DBusType.string.rawValue:
            self = .string
        case DBusType.objectPath.rawValue:
            self = .objectPath
        case DBusType.signature.rawValue:
            self = .signature
        case DBusType.array.rawValue:
            self = .array
        case DBusType.variant.rawValue:
            self = .variant
        case DBusType.struct.rawValue:
            self = .struct
        case DBusType.dictEntry.rawValue:
            self = .dictEntry
        case 0:
            self = .invalid
        default:
            return nil
        }
    }
    
    /// Returns the corresponding C constant for this type.
    ///
    /// This method returns the C constant defined in the D-Bus library
    /// that corresponds to this Swift enum value.
    ///
    /// - Returns: The corresponding C constant from the D-Bus library.
    public func toCType() -> Int32 {
        switch self {
        case .byte:
            return DBUS_TYPE_BYTE
        case .boolean:
            return DBUS_TYPE_BOOLEAN
        case .int16:
            return DBUS_TYPE_INT16
        case .uint16:
            return DBUS_TYPE_UINT16
        case .int32:
            return DBUS_TYPE_INT32
        case .uint32:
            return DBUS_TYPE_UINT32
        case .int64:
            return DBUS_TYPE_INT64
        case .uint64:
            return DBUS_TYPE_UINT64
        case .double:
            return DBUS_TYPE_DOUBLE
        case .string:
            return DBUS_TYPE_STRING
        case .objectPath:
            return DBUS_TYPE_OBJECT_PATH
        case .signature:
            return DBUS_TYPE_SIGNATURE
        case .array:
            return DBUS_TYPE_ARRAY
        case .variant:
            return DBUS_TYPE_VARIANT
        case .struct:
            return DBUS_TYPE_STRUCT
        case .dictEntry:
            return DBUS_TYPE_DICT_ENTRY
        case .invalid:
            return DBUS_TYPE_INVALID
        }
    }
}

/// Swift wrapper for D-Bus message types.
///
/// This enumeration represents the different types of messages that can be sent over D-Bus.
/// Each message type serves a different purpose in D-Bus communication.
///
/// - Note: The raw values correspond to the C constants defined in the D-Bus library.
///
/// ## Usage Example
///
/// ```swift
/// // Creating a new message of a specific type
/// let methodCall = DBusMessage(type: .methodCall, path: "/org/example/Object", 
///                             interface: "org.example.Interface", 
///                             member: "Method")
///
/// // Checking the type of a received message
/// if message.type == .signal {
///     // Handle signal message
/// }
/// ```
public enum DBusMessageType: Int32 {
    /// An invalid message type.
    ///
    /// This is used to indicate an error or uninitialized message.
    case invalid = 0
    
    /// A method call message.
    ///
    /// Method calls are sent by clients to servers to invoke methods on objects.
    /// They typically expect a reply (either a method return or an error).
    case methodCall = 1
    
    /// A method return message.
    ///
    /// Method returns are sent in response to method calls when the method
    /// completes successfully. They contain the return values of the method.
    case methodReturn = 2
    
    /// An error message.
    ///
    /// Error messages are sent in response to method calls when an error occurs.
    /// They contain an error name and an error message describing what went wrong.
    case error = 3
    
    /// A signal message.
    ///
    /// Signals are broadcast messages that any interested client can receive.
    /// They are used to notify clients of events or state changes.
    case signal = 4
    
    /// Returns the corresponding C constant for this message type.
    ///
    /// This method returns the C constant defined in the D-Bus library
    /// that corresponds to this Swift enum value.
    ///
    /// - Returns: The corresponding C constant from the D-Bus library.
    public func toCType() -> Int32 {
        switch self {
        case .invalid:
            return DBUS_MESSAGE_TYPE_INVALID
        case .methodCall:
            return DBUS_MESSAGE_TYPE_METHOD_CALL
        case .methodReturn:
            return DBUS_MESSAGE_TYPE_METHOD_RETURN
        case .error:
            return DBUS_MESSAGE_TYPE_ERROR
        case .signal:
            return DBUS_MESSAGE_TYPE_SIGNAL
        }
    }
}

/// Swift wrapper for D-Bus error handling.
///
/// This class provides a Swift-friendly interface for handling D-Bus errors.
/// It encapsulates the error information (name and message) and tracks whether
/// an error is currently set.
///
/// D-Bus errors consist of:
/// - A name (e.g., "org.freedesktop.DBus.Error.ServiceUnknown")
/// - A human-readable message
///
/// ## Example
///
/// ```swift
/// // Creating and using a DBusError
/// let error = DBusError()
/// 
/// // Pass the error to a D-Bus function that might set it
/// let connection = DBusConnection.connect(to: .session, error: error)
/// 
/// // Check if an error occurred
/// if error.isSet {
///     print("Error: \(error.name ?? "unknown"): \(error.message ?? "no message")")
///     error.free()
/// }
/// ```
///
/// ## Integration with C API
///
/// This class is designed to work with the C D-Bus API. When using functions from the
/// C API that take a `DBusError*` parameter, you can pass a pointer to the underlying
/// C structure using the `withUnsafeMutablePointer` method:
///
/// ```swift
/// let error = DBusError()
/// let result = error.withUnsafeMutablePointer { errorPtr in
///     return some_dbus_function(arg1, arg2, errorPtr)
/// }
/// 
/// if error.isSet {
///     // Handle error
///     error.free()
/// }
/// ```
public final class DBusError {
    /// The error name, typically in reverse-DNS format (e.g., "org.freedesktop.DBus.Error.ServiceUnknown").
    private var _name: String?
    
    /// The human-readable error message.
    private var _message: String?
    
    /// Flag indicating whether an error is currently set.
    private var _isSet: Bool = false
    
    /// Creates a new DBusError instance with no error set.
    ///
    /// Use this initializer to create an error object that can be passed to D-Bus functions
    /// that may set an error.
    public init() {
        // No need to initialize anything
    }
    
    /// The error name, typically in reverse-DNS format.
    ///
    /// Common error names include:
    /// - org.freedesktop.DBus.Error.ServiceUnknown
    /// - org.freedesktop.DBus.Error.NameHasNoOwner
    /// - org.freedesktop.DBus.Error.NoReply
    ///
    /// - Returns: The error name, or `nil` if no error is set.
    public var name: String? {
        return _name
    }
    
    /// The human-readable error message.
    ///
    /// This message provides details about what went wrong and is intended to be
    /// displayed to users or logged for debugging purposes.
    ///
    /// - Returns: The error message, or `nil` if no error is set.
    public var message: String? {
        return _message
    }
    
    /// Indicates whether an error is currently set.
    ///
    /// - Returns: `true` if an error is set, `false` otherwise.
    public var isSet: Bool {
        return _isSet
    }
    
    /// Frees the error and resets its state.
    ///
    /// Call this method when you're done handling an error to clean up resources
    /// and prepare the error object for reuse.
    public func free() {
        _name = nil
        _message = nil
        _isSet = false
    }
    
    /// Sets the error information.
    ///
    /// This method is used internally by the D-Bus wrapper to set error information
    /// when a D-Bus function reports an error.
    ///
    /// - Parameters:
    ///   - name: The error name, typically in reverse-DNS format.
    ///   - message: The human-readable error message.
    internal func setError(name: String, message: String) {
        _name = name
        _message = message
        _isSet = true
    }
    
    /// Clears the error information.
    ///
    /// This is an alias for `free()` and resets the error state.
    internal func clearError() {
        free()
    }
}
