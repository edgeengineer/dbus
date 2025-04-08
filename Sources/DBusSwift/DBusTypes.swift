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
/// let typeChar = DBusType.stringValue(DBusType.string)  // Returns "s"
///
/// // Create a type from its string representation
/// if let type = DBusType.fromString("i") {
///     // type is DBusType.int32
/// }
/// ```

// Extension to add instance methods to Int32 for DBusType compatibility
extension Int32 {
    /// Returns the string representation of this D-Bus type.
    ///
    /// - Returns: A single character string representing this D-Bus type.
    internal func stringValue() -> String {
        if let type = DBusType(rawValue: self) {
            return type.stringValue()
        }
        return ""
    }
    
    /// Returns the C type constant for this D-Bus type.
    ///
    /// - Returns: The corresponding C type constant.
    internal func toCType() -> Int32 {
        // Since we're now using the C constants directly, 
        // the toCType method just returns self
        return self
    }
}

/// Swift wrapper for D-Bus error handling.
///
/// This class provides a Swift-friendly interface for handling D-Bus errors.
/// It wraps the C DBusError structure and provides methods for checking, setting, and clearing errors.
internal struct DBusError: ~Copyable {
    /// The error name, typically in reverse-DNS format (e.g., "org.freedesktop.DBus.Error.ServiceUnknown").
    private var _name: String?
    
    /// The human-readable error message.
    private var _message: String?
    
    /// The underlying C DBusError structure.
    private let _error: UnsafeMutablePointer<CDBus.DBusError>
    
    /// Initializes a new D-Bus error.
    public init() {
        _error = UnsafeMutablePointer<CDBus.DBusError>.allocate(capacity: 1)
        dbus_error_init(_error)
    }
    
    /// Initializes a new D-Bus error with the given name and message.
    ///
    /// - Parameters:
    ///   - name: The error name, typically in reverse-DNS format.
    ///   - message: The human-readable error message.
    internal init(name: String, message: String) {
        _error = UnsafeMutablePointer<CDBus.DBusError>.allocate(capacity: 1)
        dbus_error_init(_error)
        _name = name
        _message = message
        
        dbus_set_error_const(_error, name, message)
    }
    
    deinit {
        dbus_error_free(_error)
    }
    
    /// The error name, typically in reverse-DNS format (e.g., "org.freedesktop.DBus.Error.ServiceUnknown").
    public var name: String? {
        if dbus_error_is_set(_error) != 0 {
            return String(cString: _error.pointee.name)
        }
        return _name
    }
    
    /// The human-readable error message.
    public var message: String? {
        if dbus_error_is_set(_error) != 0 {
            return String(cString: _error.pointee.message)
        }
        return _message
    }
    
    /// Checks if an error is set.
    ///
    /// - Returns: `true` if an error is set, `false` otherwise.
    public var isSet: Bool {
        return dbus_error_is_set(_error) != 0
    }
    
    /// Clears the error state.
    ///
    /// This method resets the error to an uninitialized state, freeing any resources
    /// associated with it. It's useful for reusing the same error object for multiple
    /// operations.
    ///
    /// Example:
    /// ```swift
    /// let error = DBusError()
    /// 
    /// // First operation
    /// let result1 = someDBusOperation(error: error)
    /// if error.isSet {
    ///     print("Error occurred: \(error.name ?? "") - \(error.message ?? "")")
    ///     error.clear() // Reset the error state for the next operation
    /// }
    /// 
    /// // Reuse the same error object for another operation
    /// let result2 = anotherDBusOperation(error: error)
    /// if error.isSet {
    ///     print("Error occurred: \(error.name ?? "") - \(error.message ?? "")")
    /// }
    /// ```
    public mutating func clear() {
        dbus_error_free(_error)
        dbus_error_init(_error)
        _name = nil
        _message = nil
    }
    
    /// Sets an error with the given name and message.
    ///
    /// This method manually creates a D-Bus error with a specific name and message.
    /// It's primarily intended for internal use and testing purposes.
    ///
    /// The error name should follow the D-Bus naming convention, which typically uses
    /// a reverse-DNS format (e.g., "org.freedesktop.DBus.Error.NotSupported").
    ///
    /// - Parameters:
    ///   - name: The error name, typically in reverse-DNS format.
    ///   - message: The human-readable error message.
    internal mutating func setError(name: String, message: String) {
        _name = name
        _message = message
        
        name.withCString { cName in
            message.withCString { cMessage in
                dbus_set_error_const(_error, cName, cMessage)
            }
        }
    }
    
    /// Gets the underlying C DBusError structure.
    ///
    /// This method provides access to the underlying C `DBusError` structure, which is useful
    /// when interacting with the lower-level C API functions that require a pointer to a
    /// `DBusError` structure.
    ///
    /// This is primarily intended for internal use or for advanced scenarios where you need
    /// to directly interact with the C API. In most cases, you should use the Swift-friendly
    /// methods and properties provided by this class instead.
    ///
    /// Example:
    /// ```swift
    /// let error = DBusError()
    /// 
    /// // Call a C API function that requires a DBusError pointer
    /// let connection = error.withError { dbusError in
    ///     dbus_bus_get(DBUS_BUS_SESSION, &dbusError)
    /// }
    ///
    /// // Check if an error occurred
    /// if error.isSet {
    ///     print("Failed to connect to the session bus: \(error.message ?? "")")
    ///     error.clear()
    /// }
    /// ```
    ///
    /// - Returns: A pointer to the underlying C DBusError structure.
    internal func withError<T, E: Error>(_ perform: (inout CDBus.DBusError) throws(E) -> T) throws(E) -> T {
        try perform(&_error.pointee)
    }
}
