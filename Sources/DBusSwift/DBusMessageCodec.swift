import Logging
import NIO

struct DBusMessageDecoder: ByteToMessageDecoder {
  typealias InboundOut = DBusMessage

  private let logger: DBusLogger

  init(logger: DBusLogger) {
    self.logger = logger
  }

  func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
    logger.trace("Decoding message from buffer with \(buffer.readableBytes) bytes")
    let index = buffer.readerIndex
    do {
      buffer.discardReadBytes()
      let msg = try DBusMessage(from: &buffer)
      logger.debug(
        "Successfully decoded D-Bus message: type=\(msg.messageType), serial=\(msg.serial)")
      context.fireChannelRead(self.wrapInboundOut(msg))
      return .continue
    } catch DBusError.truncatedHeaderFields, DBusError.truncatedBody {
      // Not enough data yet
      logger.trace("Not enough data for complete message, waiting for more")
      buffer.moveReaderIndex(to: index)
      return .needMoreData
    } catch {
      logger.error("Failed to decode D-Bus message: \(error)")
      throw error
    }
  }
}

struct DBusMessageEncoder: MessageToByteEncoder {
  typealias OutboundIn = DBusMessage

  private let logger: DBusLogger

  init(logger: DBusLogger) {
    self.logger = logger
  }

  func encode(data: DBusMessage, out: inout ByteBuffer) throws {
    logger.debug("Encoding D-Bus message: type=\(data.messageType), serial=\(data.serial)")
    data.write(to: &out)
    logger.trace("Encoded message to \(out.readableBytes) bytes")
  }
}
