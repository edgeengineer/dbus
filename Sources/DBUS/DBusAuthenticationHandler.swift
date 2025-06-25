import Logging
import NIO
import NIOCore
import NIOExtras

/// Authentication types supported for D-Bus connections.
///
/// D-Bus supports several authentication mechanisms. This library currently implements
/// ANONYMOUS and EXTERNAL authentication methods.
///
/// ## Overview
///
/// Authentication is the first step when establishing a D-Bus connection. The client and server
/// negotiate which authentication mechanism to use before any D-Bus messages can be exchanged.
///
/// ## Supported Authentication Types
///
/// - **Anonymous**: No credentials are required. This is typically used for session buses
///   or when security is handled at a different layer.
/// - **External**: Uses the process's user ID for authentication. This is commonly used
///   for system buses where the operating system has already authenticated the user.
///
/// ## Example
/// ```swift
/// // Anonymous authentication
/// let client = try await DBusClient.withConnection(to: address, auth: .anonymous) { ... }
///
/// // External authentication with current user ID
/// let userID = String(getuid())
/// let client = try await DBusClient.withConnection(to: address, auth: .external(userID: userID)) { ... }
/// ```
///
/// - SeeAlso: [D-Bus Authentication Mechanisms](https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms)
public struct AuthType: Sendable {
  internal enum Backing: Sendable {
    /// Anonymous authentication (no credentials)
    /// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms-anonymous
    case anonymous

    /// External authentication using provided user ID
    /// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms-external
    case external(userID: String)
  }

  let backing: Backing

  /// Anonymous authentication that requires no credentials.
  ///
  /// This authentication method is typically used for:
  /// - Session buses where all processes belong to the same user
  /// - Test environments
  /// - Situations where security is handled at a different layer
  ///
  /// - SeeAlso: [D-Bus ANONYMOUS Authentication](https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms-anonymous)
  public static let anonymous = AuthType(backing: .anonymous)

  /// External authentication using a provided user ID.
  ///
  /// This authentication method uses the operating system's user ID to authenticate
  /// the connection. It's commonly used for system buses where the OS has already
  /// authenticated the user.
  ///
  /// - Parameter userID: The user ID to use for authentication, typically obtained from `getuid()`.
  /// - Returns: An `AuthType` configured for external authentication.
  ///
  /// ## Example
  /// ```swift
  /// import Foundation
  ///
  /// let userID = String(getuid())
  /// let auth = AuthType.external(userID: userID)
  /// ```
  ///
  /// - SeeAlso: [D-Bus EXTERNAL Authentication](https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms-external)
  public static func external(userID: String) -> AuthType {
    AuthType(backing: .external(userID: userID))
  }
}

/// Handles the DBus authentication protocol
/// This channel handler implements the client-side of the DBus authentication protocol
/// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-protocol
internal final class DBusAuthenticationHandler: ChannelDuplexHandler, @unchecked Sendable {
  internal typealias InboundIn = ByteBuffer
  internal typealias InboundOut = ByteBuffer
  internal typealias OutboundIn = ByteBuffer
  internal typealias OutboundOut = ByteBuffer

  /// States of the DBus authentication protocol
  /// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-protocol
  internal enum State {
    /// Waiting for NUL byte reply from server (initial state)
    case waitingForNullReply
    /// Authentication sent, waiting for OK response
    case waitingForOK
    /// Successfully authenticated, normal message passing can begin
    case authenticated
    /// Authentication failed
    case failed
  }

  private var state: State = .waitingForNullReply
  private var buffer = ByteBufferAllocator().buffer(capacity: 128)
  private let auth: AuthType
  private let logger: Logger
  private var writeBuffer = [ByteBuffer]()

  internal init(auth: AuthType, logger: Logger) {
    self.auth = auth
    self.logger = logger
  }

  internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    var buf = self.unwrapInboundIn(data)
    buffer.writeBuffer(&buf)
    processBuffer(context: context)
  }

  private func processBuffer(context: ChannelHandlerContext) {
    defer { buffer.discardReadBytes() }
    while buffer.readableBytes > 0 {
      switch state {
      case .waitingForNullReply:
        // Wait for server's NUL byte reply (optional, but some servers send it)
        if let byte = buffer.getInteger(at: buffer.readerIndex, as: UInt8.self), byte == 0 {
          buffer.moveReaderIndex(forwardBy: 1)
          logger.trace("Received initial NUL byte from server")
        }

        state = .waitingForOK
        logger.debug("Waiting for authentication response from server")
      case .waitingForOK:
        guard var line = buffer.readString(length: buffer.readableBytes) else { return }
        logger.trace(
          "Received authentication response",
          metadata: [
            "response": "\(line.trimmingCharacters(in: .whitespacesAndNewlines))"
          ]
        )

        if line.starts(with: "OK ") {
          line = String(line.dropFirst(3))
          logger.debug("Authentication successful, sending BEGIN command")

          let begin = "BEGIN\r\n"
          let out = context.channel.allocator.buffer(string: begin)
          context.writeAndFlush(self.wrapOutboundOut(out), promise: nil)

          do {
            let handler = try context.pipeline.syncOperations.handler(
              type: ByteToMessageHandler<LineBasedFrameDecoder>.self)
            _ = context.pipeline.syncOperations.removeHandler(handler)

            // Directly process buffers after handler removal
            for buffer in self.writeBuffer {
              context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
            }
            self.writeBuffer.removeAll(keepingCapacity: true)
            self.state = .authenticated
            logger.debug("D-Bus authentication completed successfully")
            context.fireChannelActive()
            context.fireChannelWritabilityChanged()
          } catch {
            logger.debug(
              "Failed to complete authentication setup",
              metadata: [
                "error": "\(error)"
              ])
            context.fireErrorCaught(error)
          }
        } else if line.starts(with: "REJECTED ") {
          let mechanisms = String(line.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
          logger.debug(
            "Authentication rejected by server",
            metadata: [
              "available-mechanisms": "\(mechanisms)"
            ])
          context.fireErrorCaught(DBusAuthenticationError.invalidAuthCommand)
          // let mechanisms = line.split(separator: " ")
          //     .dropFirst()

          return
        } else {
          logger.debug(
            "Received unexpected authentication response",
            metadata: [
              "response": "\(line.trimmingCharacters(in: .whitespacesAndNewlines))"
            ]
          )
          state = .failed
          context.fireErrorCaught(DBusAuthenticationError.invalidAuthCommand)
          return
        }
      case .authenticated:
        if buffer.readableBytes > 0 {
          let pass = buffer.readSlice(length: buffer.readableBytes)!
          buffer.discardReadBytes()
          context.fireChannelRead(self.wrapInboundOut(pass))
        }
      case .failed:
        // Drop all data
        buffer.clear()
        context.close(promise: nil)
      }
    }
  }

  internal func write(
    context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?
  ) {
    if state == .authenticated, writeBuffer.isEmpty {
      context.writeAndFlush(data, promise: promise)
    } else {
      writeBuffer.append(self.unwrapOutboundIn(data))
    }
  }

  internal func channelWritabilityChanged(context: ChannelHandlerContext) {
    if state == .authenticated {
      context.fireChannelWritabilityChanged()
    }
  }

  /// Initiates the DBus authentication process when the channel becomes active
  /// Sends the initial NUL byte followed by the AUTH command
  /// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-command
  internal func channelActive(context: ChannelHandlerContext) {
    logger.debug("Starting D-Bus authentication")

    // Send initial NUL byte and AUTH command
    var buf = context.channel.allocator.buffer(capacity: 64)
    buf.writeInteger(UInt8(0))
    // Use EXTERNAL with empty UID (for root) or hex-encoded UID for current user
    // For now, send EXTERNAL with empty (\r\n at end)
    let auth: String

    switch self.auth.backing {
    case .anonymous:
      auth = "AUTH ANONYMOUS\r\n"
      logger.debug("Using ANONYMOUS authentication")
    case .external(let userID):
      let hex = userID.utf8.map { byte in
        let hexString = String(byte, radix: 16)
        return hexString.count == 1 ? "0\(hexString)" : hexString
      }.joined()
      auth = "AUTH EXTERNAL \(hex)\r\n"
      logger.debug(
        "Using EXTERNAL authentication",
        metadata: [
          "user-id": "\(userID)"
        ])
    }
    buf.writeString(auth)
    logger.trace(
      "Sending authentication command",
      metadata: [
        "command": "\(auth.trimmingCharacters(in: .whitespacesAndNewlines))"
      ]
    )
    context.writeAndFlush(self.wrapOutboundOut(buf), promise: nil)
  }
}

/// Errors that can occur during the DBus authentication process
/// See: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-protocol
enum DBusAuthenticationError: Error {
  /// The initial NUL byte was invalid or missing
  case invalidInitialNull
  /// Received an invalid AUTH command response
  case invalidAuthCommand
  /// The BEGIN command failed
  case invalidBegin
}

/// Events that can be triggered during the DBus authentication process
enum DBusAuthenticationEvent {
  /// Authentication was successful
  case authenticated
}
