import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Combine)
@preconcurrency import Combine

/// Provides Combine extensions for DBusSwift
@available(macOS 10.15, *)
public extension DBusConnection {
    /// Creates a publisher that emits a signal when received
    /// - Parameters:
    ///   - interface: The interface to listen for
    ///   - member: The signal name to listen for
    ///   - path: Optional object path to filter by
    /// - Returns: A publisher that emits DBusMessage objects when signals are received
    func signalPublisher(interface: String, member: String, path: String? = nil) -> AnyPublisher<DBusMessage, Error> {
        // Create a match rule
        var matchComponents = [
            "type='signal'",
            "interface='\(interface)'",
            "member='\(member)'"
        ]
        
        if let path = path {
            matchComponents.append("path='\(path)'")
        }
        
        let matchRule = matchComponents.joined(separator: ",")
        
        // Create a subject that will emit signals
        let subject = PassthroughSubject<DBusMessage, Error>()
        
        // Add match rule to connection
        do {
            try addMatch(rule: matchRule)
            
            // Create a timer to poll for signals
            let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            
            // Capture self in a local variable to avoid capturing in the closure
            let connection = self
            
            // Return a publisher that will clean up when all subscribers are gone
            return subject
                .handleEvents(receiveSubscription: { _ in
                    // Subscribe to the timer
                    timer.sink { _ in
                        do {
                            // Create a message to receive signals
                            let message = DBusMessage(type: .signal)
                            
                            // Try to receive a message with a very short timeout
                            if let receivedMsg = try connection.send(message: message, timeoutMS: 0) {
                                // Check if it matches our criteria
                                guard receivedMsg.getMessageType() == .signal else { return }
                                
                                // Get interface and member from the message using accessor methods
                                guard let messageInterface = receivedMsg.interface,
                                      let messageMember = receivedMsg.member else { return }
                                
                                // Check if it matches our criteria
                                if messageInterface == interface && messageMember == member {
                                    // Send the signal to subscribers
                                    subject.send(receivedMsg)
                                }
                            }
                        } catch {
                            // Ignore timeout errors, which are expected
                            if !error.localizedDescription.contains("timeout") {
                                subject.send(completion: .failure(error))
                            }
                        }
                    }.store(in: &self.cancellables)
                }, receiveCancel: {
                    // Remove match rule when all subscribers are gone
                    do {
                        try connection.removeMatch(rule: matchRule)
                    } catch {
                        print("Error removing match rule: \(error)")
                    }
                    
                    // Clear cancellables
                    self.cancellables.removeAll()
                })
                .eraseToAnyPublisher()
        } catch {
            // If we can't add the match rule, return a publisher that immediately fails
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    // Storage for cancellables
    private var cancellables: Set<AnyCancellable> {
        get {
            let key = "DBusConnection.cancellables"
            if let existing = objc_getAssociatedObject(self, key) as? Set<AnyCancellable> {
                return existing
            }
            let new = Set<AnyCancellable>()
            objc_setAssociatedObject(self, key, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
        set {
            let key = "DBusConnection.cancellables"
            objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// Combine extensions for DBusAsync
@available(macOS 10.15, *)
public extension DBusAsync {
    /// Calls a method and returns a publisher that emits the result
    /// - Parameters:
    ///   - destination: The bus name of the service to call
    ///   - path: The object path to call the method on
    ///   - interface: The interface containing the method
    ///   - method: The method name
    ///   - args: The arguments to pass to the method
    ///   - signature: The D-Bus signature of the arguments
    ///   - timeoutMS: Timeout in milliseconds, -1 for default, 0 for no timeout
    /// - Returns: A publisher that emits the result of the method call
    func callPublisher(
        destination: String,
        path: String,
        interface: String,
        method: String,
        args: [any Sendable] = [],
        signature: String = "",
        timeoutMS: Int32 = -1
    ) async -> AnyPublisher<[any Sendable], Error> {
        // Create a future that will execute the call when subscribed to
        return Future<[any Sendable], Error> { promise in
            // Execute the call in a task to handle async operations
            Task {
                do {
                    // Get the connection
                    let connection = self.getConnection()
                    
                    // Create a message
                    let message = DBusMessage.createMethodCall(
                        destination: destination,
                        path: path,
                        interface: interface,
                        method: method
                    )
                    
                    // Append arguments
                    if !args.isEmpty {
                        try message.appendArgs(signature: signature, args: args)
                    }
                    
                    // Send the message
                    if let reply = try connection.send(message: message, timeoutMS: timeoutMS) {
                        // Extract the result
                        let result = try reply.getArgs(signature: "")
                        promise(.success(result.map { self.convertToSendable($0) }))
                    } else {
                        promise(.failure(DBusConnectionError.messageFailed("No reply received")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates a publisher that emits signals when received
    /// - Parameters:
    ///   - interface: The interface to listen for
    ///   - member: The signal name to listen for
    ///   - path: Optional object path to filter by
    /// - Returns: A publisher that emits DBusMessage objects when signals are received
    func signalPublisher(interface: String, member: String, path: String? = nil) async -> AnyPublisher<DBusMessage, Error> {
        // Create a future that will create a connection when subscribed to
        return Future<AnyPublisher<DBusMessage, Error>, Error> { promise in
            // Execute in a task to handle async operations
            Task {
                // Get the connection
                let connection = self.getConnection()
                
                // Create a signal publisher
                let publisher = connection.signalPublisher(
                    interface: interface,
                    member: member,
                    path: path
                )
                promise(.success(publisher))
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
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
#endif
