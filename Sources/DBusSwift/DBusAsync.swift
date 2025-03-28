import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Provides a Swift concurrency-compatible interface for D-Bus operations
public actor DBusAsync {
    private let connection: DBusConnection
    
    /// Initializes a new D-Bus async interface
    /// - Parameter busType: The type of bus to connect to
    /// - Throws: DBusConnectionError if the connection fails
    public init(busType: DBusBusType = .session) throws {
        self.connection = try DBusConnection(busType: busType)
    }
    
    /// Returns the underlying DBusConnection
    /// - Returns: The DBusConnection instance
    public func getConnection() -> DBusConnection {
        return connection
    }
    
    /// Calls a method on the bus and returns the reply
    ///
    /// This method is automatically `async` because it's part of an actor, which ensures
    /// thread-safe access to the underlying connection. When calling this method, you must
    /// use `await` even though the D-Bus operation itself is synchronous.
    ///
    /// - Parameters:
    ///   - destination: The bus name of the service to call
    ///   - path: The object path to call the method on
    ///   - interface: The interface containing the method
    ///   - method: The method name
    ///   - args: The arguments to pass to the method
    ///   - signature: The D-Bus signature of the arguments
    ///   - replySignature: The D-Bus signature of the expected reply
    ///   - timeoutMS: Timeout in milliseconds, -1 for default, 0 for no timeout
    /// - Returns: The reply arguments as an array of Sendable values. Returns an empty array if:
    ///   - The reply signature is empty (indicating no return values are expected)
    ///   - No reply was received (e.g., for method calls that don't return anything)
    /// - Throws: DBusConnectionError if the call fails
    public func call(
        destination: String,
        path: String,
        interface: String,
        method: String,
        args: [any Sendable] = [],
        signature: String = "",
        replySignature: String = "",
        timeoutMS: Int32 = -1
    ) async throws -> [Sendable] {
        let msg = DBusMessage.createMethodCall(
            destination: destination,
            path: path,
            interface: interface,
            method: method
        )
        
        if !args.isEmpty {
            try msg.appendArgs(signature: signature, args: args)
        }
        
        if let reply = try connection.send(message: msg, timeoutMS: timeoutMS) {
            if replySignature.isEmpty {
                return []
            } else {
                return try reply.getArgs(signature: replySignature).map { convertToSendable($0) }
            }
        } else {
            return []
        }
    }
    
    /// Emits a signal on the bus
    ///
    /// This method is automatically `async` because it's part of an actor, which ensures
    /// thread-safe access to the underlying connection. When calling this method, you must
    /// use `await` even though the D-Bus operation itself is synchronous.
    ///
    /// - Parameters:
    ///   - path: The object path that is emitting the signal
    ///   - interface: The interface containing the signal
    ///   - name: The signal name
    ///   - args: The arguments to include in the signal
    ///   - signature: The D-Bus signature of the arguments
    /// - Throws: DBusConnectionError if emitting the signal fails
    public func emitSignal(
        path: String,
        interface: String,
        name: String,
        args: [any Sendable] = [],
        signature: String = ""
    ) async throws -> Void {
        let msg = DBusMessage.createSignal(
            path: path,
            interface: interface,
            name: name
        )
        
        if !args.isEmpty {
            try msg.appendArgs(signature: signature, args: args)
        }
        
        _ = try connection.send(message: msg)
        connection.flush()
    }
    
    /// Registers for signals on the bus
    /// - Parameters:
    ///   - interface: The interface containing the signal
    ///   - name: The signal name (or empty string for all signals)
    ///   - path: The object path to listen for signals on (or empty string for all paths)
    /// - Throws: DBusConnectionError if registering for signals fails
    public func registerForSignals(interface: String, name: String = "", path: String = "") throws -> Void {
        var rule = "type='signal',interface='\(interface)'"
        
        if !name.isEmpty {
            rule += ",member='\(name)'"
        }
        
        if !path.isEmpty {
            rule += ",path='\(path)'"
        }
        
        try connection.addMatch(rule: rule)
    }
    
    /// Unregisters from signals on the bus
    /// - Parameters:
    ///   - interface: The interface containing the signal
    ///   - name: The signal name (or empty string for all signals)
    ///   - path: The object path to listen for signals on (or empty string for all paths)
    /// - Throws: DBusConnectionError if unregistering from signals fails
    public func unregisterFromSignals(interface: String, name: String = "", path: String = "") throws -> Void {
        var rule = "type='signal',interface='\(interface)'"
        
        if !name.isEmpty {
            rule += ",member='\(name)'"
        }
        
        if !path.isEmpty {
            rule += ",path='\(path)'"
        }
        
        try connection.removeMatch(rule: rule)
    }
    
    // Helper function to convert Any to Sendable
    private func convertToSendable(_ value: Any) -> Sendable {
        switch value {
        case let val as String:
            return val
        case let val as Int:
            return val
        case let val as Int32:
            return val
        case let val as UInt32:
            return val
        case let val as Bool:
            return val
        case let val as Double:
            return val
        case let val as [Any]:
            return val.map { convertToSendable($0) }
        default:
            return "\(value)" // Fallback to string representation
        }
    }
}

// Extending DBusMessage with async methods
extension DBusMessage {
    /// Sends the message on the given connection and returns the reply asynchronously
    ///
    /// This method is marked as `async` to allow it to be called from within actors and other
    /// asynchronous contexts. The actual D-Bus operation is synchronous, but wrapping it in an
    /// async method allows it to integrate with Swift's structured concurrency model.
    ///
    /// - Parameters:
    ///   - connection: The connection to send the message on
    ///   - timeoutMS: Timeout in milliseconds, -1 for default, 0 for no timeout
    /// - Returns: The reply message if one was requested and received. Returns `nil` if:
    ///   - The message is not a method call (e.g., it's a signal)
    ///   - The message has the no-reply flag set
    ///   - The message was sent successfully but no reply is expected
    /// - Throws: DBusConnectionError if sending the message fails
    public func send(on connection: DBusConnection, timeoutMS: Int32 = -1) async throws -> DBusMessage? {
        return try connection.send(message: self, timeoutMS: timeoutMS)
    }
}