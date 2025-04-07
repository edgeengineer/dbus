import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Provides a Swift concurrency-compatible interface for D-Bus operations
public struct DBusAsync {
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
    public func call<each Arg: DBusArgument, R: Sendable>(
        destination: String,
        path: String,
        interface: String,
        method: String,
        args: repeat each Arg,
        timeoutMS: Int32 = -1,
        withReply: @Sendable (inout DBusMessage) async throws -> R
    ) async throws -> R? {
        let message = DBusMessage.createMethodCall(
            destination: destination,
            path: path,
            interface: interface,
            method: method
        )

        var iter = DBusMessageIter()
        dbus_message_iter_init_append(message.message, &iter)

        for var arg in repeat each args {
            try arg.write(into: &iter)
        }

        return try await connection.send(
            message: message,
            timeoutMS: timeoutMS,
            withReply: withReply
        )
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
    public func emitSignal<each Arg: DBusArgument>(
        path: String,
        interface: String,
        name: String,
        args: repeat each Arg
    ) async throws {
        let message = DBusMessage.createSignal(
            path: path,
            interface: interface,
            name: name
        )

        var iter = DBusMessageIter()

        dbus_message_iter_init_append(message.message, &iter)

        for var arg in repeat each args {
            try arg.write(into: &iter)
        }

        try await connection.send(message: message)
        await connection.flush()
    }
    
    /// Registers for signals on the bus
    /// - Parameters:
    ///   - interface: The interface containing the signal
    ///   - name: The signal name (or empty string for all signals)
    ///   - path: The object path to listen for signals on (or empty string for all paths)
    /// - Throws: DBusConnectionError if registering for signals fails
    public func registerForSignals(interface: String, name: String = "", path: String = "") async throws -> Void {
        var rule = "type='signal',interface='\(interface)'"
        
        if !name.isEmpty {
            rule += ",member='\(name)'"
        }
        
        if !path.isEmpty {
            rule += ",path='\(path)'"
        }
        
        try await connection.addMatch(rule: rule)
    }
    
    /// Unregisters from signals on the bus
    /// - Parameters:
    ///   - interface: The interface containing the signal
    ///   - name: The signal name (or empty string for all signals)
    ///   - path: The object path to listen for signals on (or empty string for all paths)
    /// - Throws: DBusConnectionError if unregistering from signals fails
    public func unregisterFromSignals(interface: String, name: String = "", path: String = "") async throws -> Void {
        var rule = "type='signal',interface='\(interface)'"
        
        if !name.isEmpty {
            rule += ",member='\(name)'"
        }
        
        if !path.isEmpty {
            rule += ",path='\(path)'"
        }
        
        try await connection.removeMatch(rule: rule)
    }
}
