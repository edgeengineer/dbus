import NIO
import NIOCore
import NIOExtras
import Logging

@available(macOS 10.15, iOS 13, *)
public struct DBusClient: Sendable {
    private let group: EventLoopGroup
    private let asyncChannel: NIOAsyncChannel<DBusMessage, DBusMessage>

    public static func withConnection<R: Sendable>(
        to address: SocketAddress,
        auth: AuthType,
        _ handler: @Sendable @escaping (
            NIOAsyncChannelInboundStream<DBusMessage>,
            NIOAsyncChannelOutboundWriter<DBusMessage>
        ) async throws -> R
    ) async throws -> R {
        let bootstrap = ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .channelInitializer { channel in
                do {
                    try DBusClient.addToPipeline(channel.pipeline, auth: auth)
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
            try await handler(inbound, outbound)
        }
    }

    public static func addToPipeline(_ pipeline: ChannelPipeline, auth: AuthType) throws {
        let handlers: [any ChannelHandler] = [
            ByteToMessageHandler(LineBasedFrameDecoder()),
            DBusAuthenticationHandler(auth: auth),
            ByteToMessageHandler(DBusMessageDecoder()),
            MessageToByteHandler(DBusMessageEncoder()),
        ]
        try pipeline.syncOperations.addHandlers(handlers)
    }
}

public enum DBusClientError: Error {
    case notConnected
} 