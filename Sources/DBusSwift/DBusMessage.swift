import CDBus
#if os(Linux)
import Glibc // Import Glibc for strdup, free, etc. on Linux
#elseif os(macOS)
import Darwin // On macOS, these are in Darwin
#endif
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public protocol DBusArgument {
    static var dbusType: DBusType { get }
    mutating func write(into iter: inout DBusMessageIter) throws
}

extension DBusArgument where Self: FixedWidthInteger {
    public static var dbusType: DBusType { .uint64 }

    public mutating func write(into iter: inout DBusMessageIter) throws {
        if dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), &self) == 0 {
            throw DBusConnectionError.messageFailed("Failed to append \(Self.dbusType)")
        }
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
}

extension String: DBusArgument {
    public static var dbusType: DBusType { .string }
    public mutating func write(into iter: inout DBusMessageIter) throws {
        let result = withCString { cString in
            dbus_message_iter_append_basic(&iter, Int32(Self.dbusType.rawValue), cString)
        }

        if result == 0 {
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
}

/// Represents a D-Bus message
public class DBusMessage {
    private(set) var message: OpaquePointer?
    private var freeOnDeinit: Bool
    
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
    
    /// Returns the underlying D-Bus message pointer
    /// - Returns: The D-Bus message pointer
    public func getMessage() -> OpaquePointer? {
        return message
    }
    
    /// Gets the message type
    /// - Returns: The message type
    public func getMessageType() -> DBusMessageType {
        guard let message = message else {
            return .invalid
        }
        
        let type = dbus_message_get_type(message)
        return DBusMessageType(rawValue: type) ?? .invalid
    }
    
    /// Gets the interface of the message
    public var interface: String? {
        get {
            guard let message else {
                return nil
            }
            
            guard let cInterface = dbus_message_get_interface(message) else {
                return nil
            }
            
            return String(cString: cInterface)
        }
    }
    
    /// Gets the member (method or signal name) of the message
    public var member: String? {
        get {
            guard let message else {
                return nil
            }
            
            guard let cMember = dbus_message_get_member(message) else {
                return nil
            }
            
            return String(cString: cMember)
        }
    }
    
    /// Gets the path of the message
    public var path: String? {
        get {
            guard let message else {
                return nil
            }
            
            guard let cPath = dbus_message_get_path(message) else {
                return nil
            }
            
            return String(cString: cPath)
        }
    }
    
    /// Gets the destination of the message
    public var destination: String? {
        get {
            guard let message else {
                return nil
            }
            
            guard let cDestination = dbus_message_get_destination(message) else {
                return nil
            }
            
            return String(cString: cDestination)
        }
    }
    
    /// Gets the sender of the message
    public var sender: String? {
        get {
            guard let message else {
                return nil
            }
            
            guard let cSender = dbus_message_get_sender(message) else {
                return nil
            }
            
            return String(cString: cSender)
        }
    }
    
    /// Gets the destination of the message
    /// - Returns: The destination of the message, or nil if not set
    public func getDestination() -> String? {
        return destination
    }
    
    /// Sets the destination of the message
    /// - Parameter destination: The destination to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setDestination(_ destination: String) -> Bool {
        guard let message else { return false }
        
        return dbus_message_set_destination(message, destination) != 0
    }
    
    /// Gets the path of the message
    /// - Returns: The path of the message, or nil if not set
    public func getPath() -> String? {
        return path
    }
    
    /// Sets the path of the message
    /// - Parameter path: The path to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setPath(_ path: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_path(message, path) != 0
    }
    
    /// Gets the interface of the message
    /// - Returns: The interface of the message, or nil if not set
    public func getInterface() -> String? {
        return interface
    }
    
    /// Sets the interface of the message
    /// - Parameter interface: The interface to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setInterface(_ interface: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_interface(message, interface) != 0
    }
    
    /// Gets the member of the message
    /// - Returns: The member of the message, or nil if not set
    public func getMember() -> String? {
        return member
    }
    
    /// Sets the member of the message
    /// - Parameter member: The member to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setMember(_ member: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_member(message, member) != 0
    }
    
    /// Gets the sender of the message
    /// - Returns: The sender of the message, or nil if not set
    public func getSender() -> String? {
        return sender
    }
    
    /// Sets the sender of the message
    /// - Parameter sender: The sender to set
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setSender(_ sender: String) -> Bool {
        guard let message else {
            return false
        }
        
        return dbus_message_set_sender(message, sender) != 0
    }
    
    /// Sets whether this message should cause the service to auto-start if it's not running
    /// - Parameter autoStart: Whether to auto-start the service
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setAutoStart(_ autoStart: Bool) -> Bool {
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
    public func appendArgs<each Arg: DBusArgument>(signature: String, args: repeat each Arg) throws {
        var iter = DBusMessageIter()
        
        dbus_message_iter_init_append(message, &iter)
        
        for var arg in repeat each args {
            try arg.write(into: &iter)
        }
    }
    
    /// Appends arguments to the message with automatic signature detection
    /// - Parameter args: The arguments to append
    /// - Throws: DBusConnectionError if appending arguments fails
    public func appendArguments<each Arg: DBusArgument>(_ args: repeat each Arg) throws {
        guard let message = message else {
            throw DBusConnectionError.messageFailed("Invalid message")
        }
        
        var iter = DBusMessageIter()
        dbus_message_iter_init_append(message, &iter)
        
        for var arg in repeat each args {
            try arg.write(into: &iter)
        }
    }
    
    /// Extracts arguments from the message
    /// - Parameter signature: The D-Bus signature of the arguments
    /// - Returns: The extracted arguments
    /// - Throws: DBusConnectionError if extracting arguments fails
    public func getArgs(signature: String) throws -> [Any] {
        guard let message = message else {
            throw DBusConnectionError.messageFailed("Invalid message")
        }
        
        var iter = DBusMessageIter()
        var args: [Any] = []
        
        if dbus_message_iter_init(message, &iter) == 0 {
            // No arguments
            return []
        }
        
        var signatureIndex = signature.startIndex
        
        repeat {
            guard signatureIndex < signature.endIndex else {
                break
            }
            
            let typeChar = signature[signatureIndex]
            signatureIndex = signature.index(after: signatureIndex)
            
            if let arg = try extractArgFromIter(iter: &iter, typeChar: typeChar) {
                args.append(arg)
            }
            
        } while dbus_message_iter_next(&iter) != 0
        
        return args
    }
    
    // Helper function to extract a single argument from a message iterator
    private func extractArgFromIter(iter: inout DBusMessageIter, typeChar: Character) throws -> Any? {
        let type = dbus_message_iter_get_arg_type(&iter)

        guard let type = DBusType(rawValue: type), type != .invalid else {
            return nil
        }

        switch type {
        case .byte:
            var val: UInt8 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .boolean:
            var val: DBusBool = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val != 0
            
        case .int16:
            var val: Int16 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .uint16:
            var val: UInt16 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .int32:
            var val: Int32 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .uint32:
            var val: UInt32 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .int64:
            var val: Int64 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .uint64:
            var val: UInt64 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .double:
            var val: Double = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case .string, .objectPath, .signature:
            var cString: UnsafePointer<CChar>? = nil
            dbus_message_iter_get_basic(&iter, &cString)
            if let cString = cString {
                return String(validatingCString: cString)
            }
            return nil
            
        default:
            throw DBusConnectionError.messageFailed("Unsupported type: \(type)")
        }
    }
}
