import Logging
import NIO

struct DBusMessageDecoder: ByteToMessageDecoder {
  typealias InboundOut = DBusMessage

  private let logger: Logger

  init(logger: Logger) {
    self.logger = logger
  }

  func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
    buffer.discardReadBytes()
    logger.trace("Decoding message from buffer with \(buffer.readableBytes) bytes")
    let index = buffer.readerIndex
    do {
      let msg = try DBusMessage(from: &buffer)
      logger.trace(
        "Successfully decoded D-Bus message",
        metadata: [
          "type": "\(msg.messageType)",
          "serial": "\(msg.serial)",
        ]
      )
      context.fireChannelRead(self.wrapInboundOut(msg))
      return .continue
    } catch DBusError.truncatedHeaderFields, DBusError.truncatedBody {
      // Not enough data yet
      logger.trace("Not enough data for complete message, waiting for more")
      buffer.moveReaderIndex(to: index)
      return .needMoreData
    } catch {
      buffer.moveReaderIndex(to: index)
      logger.debug(
        "Failed to decode D-Bus message",
        metadata: [
          "error": "\(error)"
        ])
      #if DEBUG
        struct InvalidMessageError: Error {
            let bytes: [UInt8]
        }
        
        throw InvalidMessageError(bytes: Array(buffer: buffer))
      #else
        throw error
      #endif
    }
  }
}

struct DBusMessageEncoder: MessageToByteEncoder {
  typealias OutboundIn = DBusMessage

  private let logger: Logger

  init(logger: Logger) {
    self.logger = logger
  }

  func encode(data: DBusMessage, out: inout ByteBuffer) throws {
    logger.trace(
      "Encoding D-Bus message",
      metadata: [
        "type": "\(data.messageType)",
        "serial": "\(data.serial)",
      ])
    data.write(to: &out)
    logger.trace(
      "Encoded message to bytes",
      metadata: [
        "byte-size": "\(out.readableBytes)"
      ])
  }
}
