import CDBus
#if os(Linux)
import Glibc // Import Glibc for strdup, free, etc. on Linux
#elseif os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import Darwin // On Apple platforms, these are often in Darwin or implicitly via Foundation
#endif
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Represents a D-Bus message
public class DBusMessage {
    private var message: OpaquePointer?
    private var freeOnDeinit: Bool
    
    /// Initializes a new D-Bus message
    /// - Parameter type: The message type
    public init(type: DBusMessageType) {
        message = dbus_message_new(type.rawValue)
        freeOnDeinit = true
    }
    
    /// Initializes with an existing D-Bus message pointer
    /// - Parameters:
    ///   - message: The D-Bus message pointer
    ///   - freeOnDeinit: Whether to free the message when this object is deallocated
    public init(message: OpaquePointer, freeOnDeinit: Bool = false) {
        self.message = message
        self.freeOnDeinit = freeOnDeinit
    }
    
    /// Creates a new method call message
    public static func createMethodCall(destination: String, path: String, interface: String, method: String) -> DBusMessage {
        let msg = DBusMessage(type: .methodCall)
        
        _ = destination.withCString { cDestination in
            dbus_message_set_destination(msg.message, cDestination)
        }
        
        _ = path.withCString { cPath in
            dbus_message_set_path(msg.message, cPath)
        }
        
        _ = interface.withCString { cInterface in
            dbus_message_set_interface(msg.message, cInterface)
        }
        
        _ = method.withCString { cMethod in
            dbus_message_set_member(msg.message, cMethod)
        }
        
        return msg
    }
    
    /// Creates a new signal message
    public static func createSignal(path: String, interface: String, name: String) -> DBusMessage {
        let msg = DBusMessage(type: .signal)
        
        _ = path.withCString { cPath in
            dbus_message_set_path(msg.message, cPath)
        }
        
        _ = interface.withCString { cInterface in
            dbus_message_set_interface(msg.message, cInterface)
        }
        
        _ = name.withCString { cName in
            dbus_message_set_member(msg.message, cName)
        }
        
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
    
    /// Gets the destination of the message
    /// - Returns: The destination or nil if not set
    public func getDestination() -> String? {
        guard let message = message else {
            return nil
        }
        
        guard let cString = dbus_message_get_destination(message) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Sets the destination of the message
    /// - Parameter destination: The destination
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setDestination(_ destination: String) -> Bool {
        guard let message = message else {
            return false
        }
        
        return destination.withCString { cString in
            dbus_message_set_destination(message, cString) != 0
        }
    }
    
    /// Gets the path of the message
    /// - Returns: The path or nil if not set
    public func getPath() -> String? {
        guard let message = message else {
            return nil
        }
        
        guard let cString = dbus_message_get_path(message) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Sets the path of the message
    /// - Parameter path: The path
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setPath(_ path: String) -> Bool {
        guard let message = message else {
            return false
        }
        
        return path.withCString { cString in
            dbus_message_set_path(message, cString) != 0
        }
    }
    
    /// Gets the interface of the message
    /// - Returns: The interface or nil if not set
    public func getInterface() -> String? {
        guard let message = message else {
            return nil
        }
        
        guard let cString = dbus_message_get_interface(message) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Sets the interface of the message
    /// - Parameter interface: The interface
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setInterface(_ interface: String) -> Bool {
        guard let message = message else {
            return false
        }
        
        return interface.withCString { cString in
            dbus_message_set_interface(message, cString) != 0
        }
    }
    
    /// Gets the member of the message
    /// - Returns: The member or nil if not set
    public func getMember() -> String? {
        guard let message = message else {
            return nil
        }
        
        guard let cString = dbus_message_get_member(message) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Sets the member of the message
    /// - Parameter member: The member
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setMember(_ member: String) -> Bool {
        guard let message = message else {
            return false
        }
        
        return member.withCString { cString in
            dbus_message_set_member(message, cString) != 0
        }
    }
    
    /// Gets the sender of the message
    /// - Returns: The sender or nil if not set
    public func getSender() -> String? {
        guard let message = message else {
            return nil
        }
        
        guard let cString = dbus_message_get_sender(message) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Sets the sender of the message
    /// - Parameter sender: The sender
    /// - Returns: true if successful, false otherwise
    @discardableResult
    public func setSender(_ sender: String) -> Bool {
        guard let message = message else {
            return false
        }
        
        return sender.withCString { cString in
            dbus_message_set_sender(message, cString) != 0
        }
    }
    
    /// Appends arguments to the message
    /// - Parameters:
    ///   - signature: The D-Bus signature of the arguments
    ///   - args: The arguments to append
    /// - Throws: DBusConnectionError if appending arguments fails
    public func appendArgs(signature: String, args: [Any]) throws {
        guard let message = message else {
            throw DBusConnectionError.messageFailed("Invalid message")
        }
        
        var iter = DBusMessageIter()
        
        dbus_message_iter_init_append(message, &iter)
        
        try appendArgsToIter(iter: &iter, signature: signature, args: args)
    }
    
    /// Appends arguments to the message with automatic signature detection
    /// - Parameter args: The arguments to append
    /// - Throws: DBusConnectionError if appending arguments fails
    public func appendArguments(_ args: Any...) throws {
        guard let message = message else {
            throw DBusConnectionError.messageFailed("Invalid message")
        }
        
        var iter = DBusMessageIter()
        dbus_message_iter_init_append(message, &iter)
        
        for arg in args {
            try appendArgWithAutoSignature(iter: &iter, arg: arg)
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
    
    // Helper function to append arguments to a message iterator
    private func appendArgsToIter(iter: inout DBusMessageIter, signature: String, args: [Any]) throws {
        var signatureIndex = signature.startIndex
        var argIndex = 0
        
        while signatureIndex < signature.endIndex && argIndex < args.count {
            let typeChar = signature[signatureIndex]
            let arg = args[argIndex]
            
            try appendArgToIter(iter: &iter, typeChar: typeChar, arg: arg)
            
            signatureIndex = signature.index(after: signatureIndex)
            argIndex += 1
        }
    }
    
    // Helper function to append a single argument to a message iterator
    private func appendArgToIter(iter: inout DBusMessageIter, typeChar: Character, arg: Any) throws {
        switch typeChar {
        case "y": // byte
            if let value = arg as? UInt8 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_BYTE, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append byte")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected UInt8 for byte type")
            }
            
        case "b": // boolean
            if let value = arg as? Bool {
                var val: DBusBool = value ? 1 : 0
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_BOOLEAN, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append boolean")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected Bool for boolean type")
            }
            
        case "n": // int16
            if let value = arg as? Int16 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT16, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append int16")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected Int16 for int16 type")
            }
            
        case "q": // uint16
            if let value = arg as? UInt16 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT16, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append uint16")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected UInt16 for uint16 type")
            }
            
        case "i": // int32
            if let value = arg as? Int32 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT32, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append int32")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected Int32 for int32 type")
            }
            
        case "u": // uint32
            if let value = arg as? UInt32 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT32, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append uint32")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected UInt32 for uint32 type")
            }
            
        case "x": // int64
            if let value = arg as? Int64 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT64, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append int64")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected Int64 for int64 type")
            }
            
        case "t": // uint64
            if let value = arg as? UInt64 {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT64, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append uint64")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected UInt64 for uint64 type")
            }
            
        case "d": // double
            if let value = arg as? Double {
                var val = value
                if dbus_message_iter_append_basic(&iter, DBUS_TYPE_DOUBLE, &val) == 0 {
                    throw DBusConnectionError.messageFailed("Failed to append double")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected Double for double type")
            }
            
        case "s": // string
            if let value = arg as? String {
                // Use a simpler approach with withCString that works on both platforms
                var success = false
                value.withCString { cString in
                    success = dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, cString) != 0
                }
                if !success {
                    throw DBusConnectionError.messageFailed("Failed to append string")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected String for string type")
            }
            
        case "o": // object path
            if let value = arg as? String {
                // Use a simpler approach with withCString that works on both platforms
                var success = false
                value.withCString { cString in
                    success = dbus_message_iter_append_basic(&iter, DBUS_TYPE_OBJECT_PATH, cString) != 0
                }
                if !success {
                    throw DBusConnectionError.messageFailed("Failed to append object path")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected String for object path type")
            }
            
        case "g": // signature
            if let value = arg as? String {
                // Use a simpler approach with withCString that works on both platforms
                var success = false
                value.withCString { cString in
                    success = dbus_message_iter_append_basic(&iter, DBUS_TYPE_SIGNATURE, cString) != 0
                }
                if !success {
                    throw DBusConnectionError.messageFailed("Failed to append signature")
                }
            } else {
                throw DBusConnectionError.messageFailed("Expected String for signature type")
            }
            
        default:
            throw DBusConnectionError.messageFailed("Unsupported type: \(typeChar)")
        }
    }
    
    // Helper function to extract a single argument from a message iterator
    private func extractArgFromIter(iter: inout DBusMessageIter, typeChar: Character) throws -> Any? {
        let type = dbus_message_iter_get_arg_type(&iter)
        
        if type == DBUS_TYPE_INVALID {
            return nil
        }
        
        switch typeChar {
        case "y": // byte
            var val: UInt8 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "b": // boolean
            var val: DBusBool = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val != 0
            
        case "n": // int16
            var val: Int16 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "q": // uint16
            var val: UInt16 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "i": // int32
            var val: Int32 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "u": // uint32
            var val: UInt32 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "x": // int64
            var val: Int64 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "t": // uint64
            var val: UInt64 = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "d": // double
            var val: Double = 0
            dbus_message_iter_get_basic(&iter, &val)
            return val
            
        case "s", "o", "g": // string, object path, signature
            var cString: UnsafePointer<CChar>? = nil
            dbus_message_iter_get_basic(&iter, &cString)
            if let cString = cString {
                return String(validatingCString: cString)
            }
            return nil
            
        default:
            throw DBusConnectionError.messageFailed("Unsupported type: \(typeChar)")
        }
    }
    
    // Helper function to append an argument with automatic signature detection
    private func appendArgWithAutoSignature(iter: inout DBusMessageIter, arg: Any) throws {
        switch arg {
        case let value as UInt8:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_BYTE, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append byte")
            }
            
        case let value as Bool:
            var val: DBusBool = value ? 1 : 0
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_BOOLEAN, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append boolean")
            }
            
        case let value as Int16:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT16, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append int16")
            }
            
        case let value as UInt16:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT16, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append uint16")
            }
            
        case let value as Int32:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT32, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append int32")
            }
            
        case let value as Int:
            var val = Int32(value)
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT32, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append int32")
            }
            
        case let value as UInt32:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT32, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append uint32")
            }
            
        case let value as Int64:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_INT64, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append int64")
            }
            
        case let value as UInt64:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_UINT64, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append uint64")
            }
            
        case let value as Double:
            var val = value
            if dbus_message_iter_append_basic(&iter, DBUS_TYPE_DOUBLE, &val) == 0 {
                throw DBusConnectionError.messageFailed("Failed to append double")
            }
            
        case let value as String:
            // Use withCString for better cross-platform compatibility
            var success = false
            value.withCString { cString in
                success = dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, cString) != 0
            }
            if !success {
                throw DBusConnectionError.messageFailed("Failed to append string")
            }
            
        case let value as [String]:
            // Handle string arrays
            var subIter = DBusMessageIter()
            
            // Create array container with signature "as"
            if dbus_message_iter_open_container(&iter, DBUS_TYPE_ARRAY, "s", &subIter) == 0 {
                throw DBusConnectionError.messageFailed("Failed to open array container")
            }
            
            // Append each string
            for str in value {
                var success = false
                str.withCString { cString in
                    success = dbus_message_iter_append_basic(&subIter, DBUS_TYPE_STRING, cString) != 0
                }
                if !success {
                    dbus_message_iter_close_container(&iter, &subIter)
                    throw DBusConnectionError.messageFailed("Failed to append string to array")
                }
            }
            
            // Close the container
            if dbus_message_iter_close_container(&iter, &subIter) == 0 {
                throw DBusConnectionError.messageFailed("Failed to close array container")
            }
            
        default:
            throw DBusConnectionError.messageFailed("Unsupported type: \(type(of: arg))")
        }
    }
}