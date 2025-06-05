import Logging
import NIO
import NIOCore
import NIOExtras

/// A client for communicating with D-Bus services.
///
/// `DBusClient` provides an asynchronous interface for connecting to and communicating with D-Bus services.
/// It handles the underlying connection management, authentication, and message encoding/decoding.
///
/// ## Overview
/// The client uses Swift's async/await pattern for all operations, making it easy to integrate with modern Swift code.
/// Messages are sent and received using the ``DBusMessage`` type.
///
/// ## Example
/// ```swift
/// let address = try SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket")
/// let result = try await DBusClient.withConnection(to: address, auth: .anonymous) { replies, send in
///     let message = DBusMessage.createMethodCall(
///         destination: "org.freedesktop.DBus",
///         path: "/org/freedesktop/DBus",
///         interface: "org.freedesktop.DBus",
///         method: "ListNames",
///         serial: 1
///     )
///     try await send(message)
///
///     if let reply = try await replies.next() {
///         // Process the reply
///         return reply
///     }
///     throw DBusError.noReply
/// }
/// ```
@available(macOS 10.15, iOS 13, *)
public struct DBusClient: Sendable {
  private let group: EventLoopGroup
  private let asyncChannel: NIOAsyncChannel<DBusMessage, DBusMessage>

  /// A type for receiving reply messages from the D-Bus connection.
  ///
  /// `Replies` provides an async sequence interface for reading incoming messages.
  /// Messages are delivered in the order they are received from the bus.
  public struct Replies {
    fileprivate var iterator: NIOAsyncChannelInboundStream<DBusMessage>.AsyncIterator

    /// Retrieves the next message from the D-Bus connection.
    ///
    /// This method suspends until a message is available or the connection is closed.
    ///
    /// - Returns: The next ``DBusMessage`` if available, or `nil` if the connection is closed.
    /// - Throws: An error if the connection fails or is interrupted.
    public mutating func next() async throws -> DBusMessage? {
      try await iterator.next()
    }
  }

  /// A type for sending messages to the D-Bus connection.
  ///
  /// `Send` provides methods for transmitting messages to the bus.
  /// All send operations are asynchronous and will complete when the message has been written to the connection.
  public struct Send {
    fileprivate let writer: NIOAsyncChannelOutboundWriter<DBusMessage>

    /// Sends a message through the D-Bus connection.
    ///
    /// - Parameter message: The ``DBusMessage`` to send.
    /// - Throws: An error if the send operation fails.
    public func send(_ message: DBusMessage) async throws {
      try await writer.write(message)
    }

    /// Sends a message through the D-Bus connection using function call syntax.
    ///
    /// This method provides a convenient way to send messages using function call syntax:
    /// ```swift
    /// try await send(message)
    /// ```
    ///
    /// - Parameter message: The ``DBusMessage`` to send.
    /// - Throws: An error if the send operation fails.
    public func callAsFunction(_ message: DBusMessage) async throws {
      try await send(message)
    }
  }

  /// Creates a connection to a D-Bus service and executes a handler with the connection.
  ///
  /// This method establishes a connection to the specified D-Bus address, performs authentication,
  /// and then executes the provided handler. The connection is automatically closed when the handler completes.
  ///
  /// - Parameters:
  ///   - address: The socket address of the D-Bus service to connect to.
  ///   - auth: The authentication type to use for the connection (e.g., `.anonymous` or `.external(userID:)`).
  ///   - logger: The logger to use for D-Bus operations. Defaults to a logger with label "dbus.client".
  ///   - handler: An async closure that receives ``Replies`` and ``Send`` instances for communicating with the bus.
  ///             The handler should return a value of type `R`.
  ///
  /// - Returns: The value returned by the handler.
  /// - Throws: An error if the connection fails, authentication fails, or the handler throws.
  ///
  /// ## Example
  /// ```swift
  /// let names = try await DBusClient.withConnection(to: address, auth: .anonymous) { replies, send in
  ///     // Send a message
  ///     try await send(listNamesMessage)
  ///
  ///     // Wait for reply
  ///     guard let reply = try await replies.next() else {
  ///         throw DBusError.noReply
  ///     }
  ///
  ///     return reply.body
  /// }
  /// ```
  public static func withConnection<R: Sendable>(
    to address: SocketAddress,
    auth: AuthType,
    logger: Logger = Logger(label: "dbus.client"),
    _ handler: @Sendable @escaping (inout Replies, Send) async throws -> R
  ) async throws -> R {
    let bootstrap = ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
      .channelInitializer { channel in
        do {
          try DBusClient.addToPipeline(channel.pipeline, auth: auth, logger: logger)
          return channel.eventLoop.makeSucceededVoidFuture()
        } catch {
          return channel.eventLoop.makeFailedFuture(error)
        }
      }
    let asyncChannel = try await bootstrap.connect(to: address)
      .flatMapThrowing {
        try NIOAsyncChannel(
          wrappingChannelSynchronously: $0,
          configuration: .init(
            inboundType: DBusMessage.self,
            outboundType: DBusMessage.self
          )
        )
      }.get()

    return try await asyncChannel.executeThenClose { inbound, outbound in
      var replies = Replies(
        iterator: inbound.makeAsyncIterator()
      )
      let send = Send(writer: outbound)
      return try await handler(&replies, send)
    }
  }

  static func addToPipeline(
    _ pipeline: ChannelPipeline, auth: AuthType, logger: Logger = Logger(label: "dbus.client")
  ) throws {
    let handlers: [any ChannelHandler] = [
      ByteToMessageHandler(LineBasedFrameDecoder()),
      DBusAuthenticationHandler(auth: auth, logger: logger),
      ByteToMessageHandler(DBusMessageDecoder(logger: logger)),
      MessageToByteHandler(DBusMessageEncoder(logger: logger)),
    ]
    try pipeline.syncOperations.addHandlers(handlers)
  }
}

internal enum DBusClientError: Error {
  case notConnected
}
