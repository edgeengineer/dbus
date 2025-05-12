import NIO
import Logging

struct DBusMessageDecoder: ByteToMessageDecoder {
    typealias InboundOut = DBusMessage

    private let logger = Logger(label: "dbus.nio")

    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        logger.trace("\(buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes) ?? [])")
        let index = buffer.readerIndex
        do {
            buffer.discardReadBytes()
            let msg = try DBusMessage(from: &buffer)
            context.fireChannelRead(self.wrapInboundOut(msg))
            return .continue
        } catch DBusError.truncatedHeaderFields, DBusError.truncatedBody {
            // Not enough data yet
            buffer.moveReaderIndex(to: index)
            return .needMoreData
        } catch {
            throw error
        }
    }
}

struct DBusMessageEncoder: MessageToByteEncoder {
    typealias OutboundIn = DBusMessage

    func encode(data: DBusMessage, out: inout ByteBuffer) throws {
        data.write(to: &out)
    }
} 