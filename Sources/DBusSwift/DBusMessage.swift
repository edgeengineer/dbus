import CDBus
 // Imports for strdup, free, etc. on Linux
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#endif
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public protocol DBusArgument: Sendable {
    static var dbusType: DBusType { get }
    init(from iter: inout DBusMessageIter) throws
    mutating func write(into iter: inout DBusMessageIter) throws
}

extension DBusMessageIter {
    public mutating func parse<Value: DBusArgument>(
        as value: Value.Type
    ) throws -> Value {
        try Value(from: &self)
    }
}

extension DBusMessage {
    public mutating func parse<Value: DBusArgument>(
        as value: Value.Type
    ) throws -> Value {
        try withValues { iter in
            try Value(from: &iter)
        }
    }
}

extension DBusArgument where Self: FixedWidthInteger {
    public static var dbusType: DBusType { .uint64 }

    public mutating func write(into iter: inout DBusMessageIter) throws {
        if dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), &self) == 0 {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
    }

    public init(from iter: inout DBusMessageIter) throws {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard type == Self.dbusType.rawValue else {
            throw DBusConnectionError.messageFailed("Failed to parse \(Self.dbusType), found \(type)")
        }

        var value: Self = 0
        dbus_message_iter_get_basic(&iter, &value)
        self = value
    }
}

extension UInt8: DBusArgument {
    public static var dbusType: DBusType { .byte }
}

extension Bool: DBusArgument {
    public static var dbusType: DBusType { .boolean }
    public mutating func write(into iter: inout DBusMessageIter) throws {
        var value: DBusBool = self ? 1 : 0
        if dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), &value) == 0 {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
    }

    public init(from iter: inout DBusMessageIter) throws {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard type == Self.dbusType.rawValue else {
            throw DBusConnectionError.messageFailed("Failed to parse \(Self.dbusType), found \(type)")
        }

        var val: DBusBool = 0
        dbus_message_iter_get_basic(&iter, &val)
        self = val != 0
    }
}

extension Int16: DBusArgument {
    public static var dbusType: DBusType { .int16 }
}

extension UInt16: DBusArgument {
    public static var dbusType: DBusType { .uint16 }
}

extension Int32: DBusArgument {
    public static var dbusType: DBusType { .int32 }
}

extension UInt32: DBusArgument {
    public static var dbusType: DBusType { .uint32 }
}

extension Int64: DBusArgument {
    public static var dbusType: DBusType { .int64 }
}

extension UInt64: DBusArgument {
    public static var dbusType: DBusType { .uint64 }
}

extension Double: DBusArgument {
    public static var dbusType: DBusType { .double }
    public mutating func write(into iter: inout DBusMessageIter) throws {
        if dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), &self) == 0 {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
    }

    public init(from iter: inout DBusMessageIter) throws {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard type == Self.dbusType.rawValue else {
            throw DBusConnectionError.messageFailed("Failed to parse \(Self.dbusType), found \(type)")
        }

        var val: Double = 0
        dbus_message_iter_get_basic(&iter, &val)
        self = val
    }
}

extension String: DBusArgument {
    public static var dbusType: DBusType { .string }
    public mutating func write(into iter: inout DBusMessageIter) throws {
        let result = withCString { cString in
            var cString = cString
            return dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), &cString)
        }

        if result == 0 {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
    }

    public init(from iter: inout DBusMessageIter) throws {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard type == Self.dbusType.rawValue else {
            throw DBusConnectionError.messageFailed("Failed to parse \(Self.dbusType), found \(type)")
        }

        var cString: UnsafePointer<CChar>? = nil
        dbus_message_iter_get_basic(&iter, &cString)
        if let cString, let string = String(validatingCString: cString) {
            self = string
        } else {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
    }
}

extension Array: DBusArgument where Element: DBusArgument {
    public static var dbusType: DBusType { .array }
    public mutating func write(into iter: inout DBusMessageIter) throws {
        // Create an array iterator
        var subIter = DBusMessageIter()
        let subValue = String(Character(Unicode.Scalar(UInt8(Element.dbusType.rawValue))))
        try subValue.withCString { cString in
            if dbus_message_iter_open_container(&iter, Int32(DBusType.array.rawValue), cString, &subIter) == 0 {
                throw DBusConnectionError.messageFailed("Failed to open array container")
            }
        }

        for var value in self {
            do {
                try value.write(into: &subIter)
            } catch {
                dbus_message_iter_close_container(&iter, &subIter)
                throw error
            }
        }
        
        // Close the array container
        if dbus_message_iter_close_container(&iter, &subIter) == 0 {
            throw DBusConnectionError.messageFailed("Failed to close array container")
        }
    }

    public init(from iter: inout DBusMessageIter) throws {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard type == Self.dbusType.rawValue else {
            throw DBusConnectionError.messageFailed("Failed to parse \(Self.dbusType), found \(type)")
        }

        var subIter = DBusMessageIter()
        dbus_message_iter_recurse(&iter, &subIter)
        
        var array: [Element] = []
        while dbus_message_iter_get_arg_type(&subIter) != Int32(DBusType.invalid.rawValue) {
            let element = try Element(from: &subIter)
            array.append(element)
            dbus_message_iter_next(&subIter)
        }
        
        self = array
    }
}

/// Represents a D-Bus message
public struct DBusMessage: ~Copyable, @unchecked Sendable {
    private(set) var message: OpaquePointer?
    private var freeOnDeinit: Bool

    public func withValues<R>(
        parse: (inout DBusMessageIter) throws -> R
    ) throws -> R {
        var iter = DBusMessageIter()
        if dbus_message_iter_init(message, &iter) == 0 {
            throw DBusConnectionError.parsingFailed("Could not construct message iterator")
        }
        return try parse(&iter)
    }

    /// Initializes a new D-Bus message
    /// - Parameter type: The message type
    public init(type: DBusMessageType) {
        let messageType = type.rawValue
        message = dbus_message_new(messageType)
        freeOnDeinit = true
    }
    
    /// Initializes with an existing D-Bus message pointer
    /// - Parameters:
    ///   - message: The D-Bus message pointer
    ///   - freeOnDeinit: Whether to free the message when this object is deallocated
    public init(message: OpaquePointer?, freeOnDeinit: Bool = true) {
        self.message = message
        self.freeOnDeinit = freeOnDeinit
        
        if freeOnDeinit, let message = message {
            dbus_message_ref(message)
        }
    }
    
    /// Creates a new method call message
    public static func createMethodCall(destination: String, path: String, interface: String, method: String) -> DBusMessage {
        let msg = DBusMessage(type: .methodCall)
        
        dbus_message_set_destination(msg.message, destination)
        
        dbus_message_set_path(msg.message, path)
        
        dbus_message_set_interface(msg.message, interface)
        
        dbus_message_set_member(msg.message, method)
        
        return msg
    }
    
    /// Creates a new signal message
    public static func createSignal(path: String, interface: String, name: String) -> DBusMessage {
        let msg = DBusMessage(type: .signal)
        
        dbus_message_set_path(msg.message, path)
        
        dbus_message_set_interface(msg.message, interface)
        
        dbus_message_set_member(msg.message, name)
        
        return msg
    }
    
    deinit {
        if freeOnDeinit, let message = message {
            dbus_message_unref(message)
        }
    }
    
    /// Gets the message type
    /// - Returns: The message type
    public var messageType: DBusMessageType {
        guard let message else {
            return .invalid
        }
        
        let type = dbus_message_get_type(message)
        return DBusMessageType(rawValue: type) ?? .invalid
    }
    
    /// Gets the interface of the message
    public var interface: String? {
        guard let message else {
            return nil
        }

        guard let cInterface = dbus_message_get_interface(message) else {
            return nil
        }

        return String(cString: cInterface)
    }
    
    /// Gets the member (method or signal name) of the message
    public var member: String? {
        guard let message else {
            return nil
        }

        guard let cMember = dbus_message_get_member(message) else {
            return nil
        }

        return String(cString: cMember)
    }
    
    /// Gets the path of the message
    public var path: String? {
        guard let message else {
            return nil
        }

        guard let cPath = dbus_message_get_path(message) else {
            return nil
        }

        return String(cString: cPath)
    }
    
    /// Gets the destination of the message
    public var destination: String? {
        guard let message else {
            return nil
        }

        guard let cDestination = dbus_message_get_destination(message) else {
            return nil
        }

        return String(cString: cDestination)
    }
    
    /// Gets the sender of the message
    public var sender: String? {
        guard let message else {
            return nil
        }

        guard let cSender = dbus_message_get_sender(message) else {
            return nil
        }

        return String(cString: cSender)
    }
    
    /// Sets the destination of the message
    /// - Parameter destination: The destination to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setDestination(_ destination: String) -> Bool {
        guard let message else { return false }
        
        return dbus_message_set_destination(message, destination) != 0
    }
    
    /// Sets the path of the message
    /// - Parameter path: The path to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setPath(_ path: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_path(message, path) != 0
    }
    
    /// Sets the interface of the message
    /// - Parameter interface: The interface to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setInterface(_ interface: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_interface(message, interface) != 0
    }
    
    /// Sets the member of the message
    /// - Parameter member: The member to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setMember(_ member: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_member(message, member) != 0
    }
    
    /// Sets the sender of the message
    /// - Parameter sender: The sender to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setSender(_ sender: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_sender(message, sender) != 0
    }
    
    /// Sets whether this message should cause the service to auto-start if it's not running
    /// - Parameter autoStart: Whether to auto-start the service
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public mutating func setAutoStart(_ autoStart: Bool) -> Bool {
        guard let message else { return false }
        dbus_message_set_auto_start(message, autoStart ? 1 : 0)
        return true
    }
    
    /// Gets whether this message should cause the service to auto-start if it's not running
    /// - Returns: true if auto-start is enabled, false otherwise
    public func getAutoStart() -> Bool {
        guard let message = message else { return false }
        return dbus_message_get_auto_start(message) != 0
    }
    
    /// Appends arguments to the message
    /// - Parameters:
    ///   - signature: The D-Bus signature of the arguments
    ///   - args: The arguments to append
    /// - Throws: DBusConnectionError if appending arguments fails
    public mutating func appendArgs<each Arg: DBusArgument>(signature: String, args: repeat each Arg) throws {
        var iter = DBusMessageIter()
        
        dbus_message_iter_init_append(message, &iter)
        
        for var arg in repeat each args {
            try arg.write(into: &iter)
        }
    }
    
    /// Appends arguments to the message with automatic signature detection
    /// - Parameter args: The arguments to append
    /// - Throws: DBusConnectionError if appending arguments fails
    public mutating func appendArguments<each Arg: DBusArgument>(_ args: repeat each Arg) throws {
        guard let message = message else {
            throw DBusConnectionError.messageFailed("Invalid message")
        }
        
        var iter = DBusMessageIter()
        dbus_message_iter_init_append(message, &iter)
        
        for var arg in repeat each args {
            try arg.write(into: &iter)
        }
    }
    
}
