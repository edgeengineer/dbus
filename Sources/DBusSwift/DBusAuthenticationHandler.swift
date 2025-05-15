import NIO
import NIOCore
import NIOExtras
import Logging

public enum AuthType: Sendable {
    case anonymous
    case external(userID: String)
}

public final class DBusAuthenticationHandler: ChannelDuplexHandler, @unchecked Sendable {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ByteBuffer
    public typealias OutboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    public enum State {
        case waitingForNullReply
        case waitingForOK
        case authenticated
        case failed
    }

    private var state: State = .waitingForNullReply
    private var buffer = ByteBufferAllocator().buffer(capacity: 128)
    private let auth: AuthType
    private var writeBuffer = [ByteBuffer]()

    public init(auth: AuthType) {
        self.auth = auth
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
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
                }

                state = .waitingForOK
            case .waitingForOK:
                guard var line = buffer.readString(length: buffer.readableBytes) else { return }
                if line.starts(with: "OK ") {
                    line = String(line.dropFirst(3))

                    let begin = "BEGIN\r\n"
                    let out = context.channel.allocator.buffer(string: begin)
                    context.writeAndFlush(self.wrapOutboundOut(out), promise: nil)

                    do {
                        let handler = try context.pipeline.syncOperations.handler(type: ByteToMessageHandler<LineBasedFrameDecoder>.self)
                        _ = context.pipeline.syncOperations.removeHandler(handler)
                        
                        // Directly process buffers after handler removal
                        for buffer in self.writeBuffer {
                            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
                        }
                        self.writeBuffer.removeAll(keepingCapacity: true)
                        self.state = .authenticated
                        context.fireChannelActive()
                        context.fireChannelWritabilityChanged()
                    } catch {
                        context.fireErrorCaught(error)
                    }
                } else if line.starts(with: "REJECTED ") {
                    // let mechanisms = line.split(separator: " ")
                    //     .dropFirst()

                    return
                } else {
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

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        if state == .authenticated, writeBuffer.isEmpty {
            context.writeAndFlush(data, promise: promise)
        } else {
            writeBuffer.append(self.unwrapOutboundIn(data))
        }
    }

    public func channelWritabilityChanged(context: ChannelHandlerContext) {
        if state == .authenticated {
            context.fireChannelWritabilityChanged()
        }
    }

    public func channelActive(context: ChannelHandlerContext) {
        // Send initial NUL byte and AUTH command
        var buf = context.channel.allocator.buffer(capacity: 64)
        buf.writeInteger(UInt8(0))
        // Use EXTERNAL with empty UID (for root) or hex-encoded UID for current user
        // For now, send EXTERNAL with empty (\r\n at end)
        let auth: String
        
        switch self.auth {
        case .anonymous:
            auth = "AUTH ANONYMOUS\r\n"
        case .external(let userID):
            let hex = userID.utf8.map { byte in
                let hexString = String(byte, radix: 16)
                return hexString.count == 1 ? "0\(hexString)" : hexString
            }.joined()
            auth = "AUTH EXTERNAL \(hex)\r\n"
        }
        buf.writeString(auth)
        context.writeAndFlush(self.wrapOutboundOut(buf), promise: nil)
    }
}

public enum DBusAuthenticationError: Error {
    case invalidInitialNull
    case invalidAuthCommand
    case invalidBegin
}

public enum DBusAuthenticationEvent {
    case authenticated
} 