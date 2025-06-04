import NIO
import NIOCore
import NIOExtras
import Testing

@testable import DBusSwift

@Suite
struct DBusAuthenticationHandlerTests {
  // MARK: - Authentication Protocol Tests

  @Test func initialNulByteSending() throws {
    // Set up an embedded channel using DBusClient's configuration
    let channel = EmbeddedChannel()
    try DBusClient.addToPipeline(channel.pipeline, auth: .anonymous)

    // Activate the channel
    channel.pipeline.fireChannelActive()

    // Verify the NUL byte was sent followed by AUTH command
    if let data = try channel.readOutbound(as: ByteBuffer.self) {
      #expect(data.getInteger(at: 0, as: UInt8.self) == 0, "First byte should be NUL (0)")

      // Check the AUTH command follows the NUL byte
      let command = data.getString(at: 1, length: data.readableBytes - 1)
      #expect(command == "AUTH ANONYMOUS\r\n", "Expected ANONYMOUS auth command")
    } else {
      #expect(Bool(false), "No outbound message was sent")
    }

    try channel.close().wait()
  }

  @Test func externalAuthentication() throws {
    // Test with a user ID that needs hex encoding
    let userId = "1000"
    let expectedHexUserId = userId.utf8.map { byte in
      let hexString = String(byte, radix: 16)
      return hexString.count == 1 ? "0\(hexString)" : hexString
    }.joined()

    let channel = EmbeddedChannel()
    try DBusClient.addToPipeline(channel.pipeline, auth: .external(userID: userId))

    // Activate the channel
    channel.pipeline.fireChannelActive()

    // Verify the NUL byte was sent followed by AUTH EXTERNAL command
    if let data = try channel.readOutbound(as: ByteBuffer.self) {
      #expect(data.getInteger(at: 0, as: UInt8.self) == 0, "First byte should be NUL (0)")

      // Check the AUTH command follows the NUL byte with correctly encoded user ID
      let command = data.getString(at: 1, length: data.readableBytes - 1)
      #expect(
        command == "AUTH EXTERNAL \(expectedHexUserId)\r\n",
        "Expected EXTERNAL auth command with hex-encoded user ID")
    } else {
      #expect(Bool(false), "No outbound message was sent")
    }

    try channel.close().wait()
  }

  @Test func completeAuthenticationCycle() throws {
    let channel = EmbeddedChannel()
    try DBusClient.addToPipeline(channel.pipeline, auth: .anonymous)

    // Activate the channel (sends initial NUL byte + AUTH command)
    channel.pipeline.fireChannelActive()

    // Consume the outbound message
    _ = try channel.readOutbound(as: ByteBuffer.self)

    // Send OK response from server
    var okBuffer = channel.allocator.buffer(capacity: 16)
    okBuffer.writeString("OK 1234abcd5678ef90\r\n")
    try channel.writeInbound(okBuffer)

    // Verify BEGIN command was sent
    if let beginData = try channel.readOutbound(as: ByteBuffer.self) {
      let command = String(buffer: beginData)
      #expect(command == "BEGIN\r\n", "Expected BEGIN command after authentication")
    } else {
      #expect(Bool(false), "No BEGIN command was sent")
    }

    // Test that the handler is now forwarding messages
    // Create a proper DBusMessage instead of a raw ByteBuffer
    let testMessage = DBusMessage(
      byteOrder: .little,
      messageType: .methodCall,
      flags: [],
      protocolVersion: 1,
      serial: 1,
      headerFields: [
        HeaderField(code: .path, variant: DBusVariant(.objectPath("/test/path"))),
        HeaderField(code: .interface, variant: DBusVariant(.string("org.test.Interface"))),
        HeaderField(code: .member, variant: DBusVariant(.string("TestMethod"))),
      ],
      body: []
    )

    try channel.writeAndFlush(testMessage).wait()

    // Message should be forwarded (not buffered)
    if let forwardedMessage = try channel.readOutbound(as: ByteBuffer.self) {
      // We can't directly compare the raw message, but we can check that something was sent
      #expect(forwardedMessage.readableBytes > 0, "Message should have been forwarded with content")
    } else {
      #expect(Bool(false), "No message was forwarded")
    }

    try channel.close().wait()
  }

  @Test func rejectedAuthentication() throws {
    let channel = EmbeddedChannel()
    
    // Add error handler to verify the correct error is thrown
    var capturedError: Error?
    let errorHandler = ErrorCollector { error in
      capturedError = error
    }
    try channel.pipeline.addHandler(errorHandler).wait()
    
    try DBusClient.addToPipeline(channel.pipeline, auth: .anonymous)

    // Activate the channel
    channel.pipeline.fireChannelActive()

    // Consume the outbound message
    _ = try channel.readOutbound(as: ByteBuffer.self)

    // Send REJECTED response
    var rejectedBuffer = channel.allocator.buffer(capacity: 32)
    rejectedBuffer.writeString("REJECTED EXTERNAL DBUS_COOKIE_SHA1\r\n")
    
    // This will throw an error in the handler
    do {
      try channel.writeInbound(rejectedBuffer)
    } catch {
      // Error might be thrown here too
      capturedError = error
    }

    // Verify the correct error was caught
    #expect(capturedError != nil, "An error should be thrown for REJECTED response")
    if let dbusError = capturedError as? DBusAuthenticationError {
      #expect(dbusError == .invalidAuthCommand, "Should receive invalidAuthCommand error")
    }
    
    // No BEGIN command should be sent
    #expect(
      try channel.readOutbound(as: ByteBuffer.self) == nil,
      "No command should be sent after REJECTED")

    try channel.close().wait()
  }

  @Test func channelWritabilityChanges() throws {
    let channel = EmbeddedChannel()

    // Add writability tracking handler
    var writabilityChangedBeforeAuth = false
    var writabilityChangedAfterAuth = false

    let writabilityTracker = WritabilityTracker(
      beforeAuthCallback: { writabilityChangedBeforeAuth = true },
      afterAuthCallback: { writabilityChangedAfterAuth = true }
    )
    try channel.pipeline.addHandler(writabilityTracker).wait()

    try DBusClient.addToPipeline(channel.pipeline, auth: .anonymous)

    // Activate the channel
    channel.pipeline.fireChannelActive()

    // Consume the outbound message
    _ = try channel.readOutbound(as: ByteBuffer.self)

    // Trigger writability change before authentication
    channel.pipeline.fireChannelWritabilityChanged()

    // The beforeAuthCallback should be called, but event should not propagate
    #expect(
      writabilityChangedBeforeAuth == true, "Writability tracker should detect change before auth")

    // Complete authentication
    var okBuffer = channel.allocator.buffer(capacity: 16)
    okBuffer.writeString("OK 1234abcd5678ef90\r\n")
    try channel.writeInbound(okBuffer)

    // Consume the BEGIN command
    _ = try channel.readOutbound(as: ByteBuffer.self)

    // Trigger writability change after authentication
    channel.pipeline.fireChannelWritabilityChanged()

    // Event should propagate after auth
    #expect(writabilityChangedAfterAuth == true, "Writability change should propagate after auth")

    try channel.close().wait()
  }

  @Test func partialDataHandling() throws {
    let channel = EmbeddedChannel()
    try DBusClient.addToPipeline(channel.pipeline, auth: .anonymous)

    // Activate the channel
    channel.pipeline.fireChannelActive()

    // Consume the outbound message
    _ = try channel.readOutbound(as: ByteBuffer.self)

    // Send first part of OK response
    var buffer1 = channel.allocator.buffer(capacity: 2)
    buffer1.writeString("OK")
    try channel.writeInbound(buffer1)

    // No BEGIN command should be sent yet (incomplete response)
    #expect(
      try channel.readOutbound(as: ByteBuffer.self) == nil,
      "No command should be sent for partial response")

    // Send the rest of the response
    var buffer2 = channel.allocator.buffer(capacity: 15)
    buffer2.writeString(" 1234abcd\r\n")
    try channel.writeInbound(buffer2)

    // Now the BEGIN command should be sent
    if let beginData = try channel.readOutbound(as: ByteBuffer.self) {
      let command = String(buffer: beginData)
      #expect(command == "BEGIN\r\n", "Expected BEGIN command after complete response")
    } else {
      #expect(Bool(false), "No BEGIN command was sent")
    }

    try channel.close().wait()
  }

}

// Helper handlers for testing
private final class ErrorCollector: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = ByteBuffer

  private let callback: (Error) -> Void

  init(callback: @escaping (Error) -> Void) {
    self.callback = callback
  }

  func errorCaught(context: ChannelHandlerContext, error: Error) {
    callback(error)
    context.fireErrorCaught(error)
  }
}

private final class WritabilityTracker: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = ByteBuffer

  private let beforeAuthCallback: () -> Void
  private let afterAuthCallback: () -> Void
  private var authCompleted = false

  init(beforeAuthCallback: @escaping () -> Void, afterAuthCallback: @escaping () -> Void) {
    self.beforeAuthCallback = beforeAuthCallback
    self.afterAuthCallback = afterAuthCallback
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let buffer = self.unwrapInboundIn(data)

    // Check if this is an OK message from the server
    if let str = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes),
      str.starts(with: "OK ")
    {
      authCompleted = true
    }

    context.fireChannelRead(data)
  }

  func channelWritabilityChanged(context: ChannelHandlerContext) {
    if authCompleted {
      afterAuthCallback()
      context.fireChannelWritabilityChanged()
    } else {
      beforeAuthCallback()
      // Don't propagate the event before auth
    }
  }
}

// Make DBusAuthenticationError equatable for easier testing
extension DBusAuthenticationError {
  public static func == (lhs: DBusAuthenticationError, rhs: DBusAuthenticationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidInitialNull, .invalidInitialNull),
      (.invalidAuthCommand, .invalidAuthCommand),
      (.invalidBegin, .invalidBegin):
      return true
    default:
      return false
    }
  }
}
