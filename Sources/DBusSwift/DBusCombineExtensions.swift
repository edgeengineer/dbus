import CDBus
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Combine)
@preconcurrency import Combine

/// A class to store cancellables for each DBusConnection instance
private final class CancellableStorage {
    var cancellables = Set<AnyCancellable>()
    
    // Method to add a cancellable
    func store(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }
    
    // Method to clear all cancellables
    func clear() {
        cancellables.removeAll()
    }
}

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
            
            // Create a timer to poll for signals - use a lower frequency to reduce CPU usage
            let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            
            // Create a storage for cancellables that will be captured by the closure
            let storage = CancellableStorage()
            
            // Capture self in a local variable to avoid capturing in the closure
            let connection = self
            
            // Return a publisher that will clean up when all subscribers are gone
            return subject
                .handleEvents(receiveSubscription: { _ in
                    // Subscribe to the timer
                    timer.sink { _ in
                        // Create a message to receive signals
                        let message = DBusMessage(type: .signal)
                        
                        do {
                            // Try to receive a message with a very short timeout
                            if let receivedMsg = try connection.send(message: message, timeoutMS: 0) {
                                // Check if it matches our criteria
                                let messageType = receivedMsg.getMessageType()
                                guard messageType == .signal else { return }
                                
                                // Get interface and member from the message using accessor methods
                                guard let messageInterface = receivedMsg.getInterface(),
                                      let messageMember = receivedMsg.getMember() else { return }
                                
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
                    }.store(in: &storage.cancellables)
                }, receiveCancel: {
                    // Remove match rule when all subscribers are gone
                    do {
                        try connection.removeMatch(rule: matchRule)
                    } catch {
                        print("Error removing match rule: \(error)")
                    }
                    
                    // Clear cancellables
                    storage.clear()
                })
                .eraseToAnyPublisher()
        } catch {
            // If we can't add the match rule, return a publisher that immediately fails
            return Fail(error: error).eraseToAnyPublisher()
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
                do {
                    // Get the connection
                    let connection = self.getConnection()
                    
                    // Create a signal publisher
                    let publisher = connection.signalPublisher(
                        interface: interface,
                        member: member,
                        path: path
                    )
                    promise(.success(publisher))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    // Helper function to convert Any to Sendable
    private func convertToSendable(_ value: Any) -> any Sendable {
        // Handle specific types directly to avoid runtime type checking issues
        if let val = value as? String {
            return val
        } else if let val = value as? Int {
            return val
        } else if let val = value as? Int32 {
            return val
        } else if let val = value as? UInt32 {
            return val
        } else if let val = value as? Bool {
            return val
        } else if let val = value as? Double {
            return val
        } else if let val = value as? [Any] {
            return val.map { convertToSendable($0) }
        } else if let val = value as? [String: Any] {
            var result = [String: any Sendable]()
            for (key, innerValue) in val {
                result[key] = convertToSendable(innerValue)
            }
            return result
        } else {
            // Fallback to string representation for unknown types
            return String(describing: value)
        }
    }
}
#endif
