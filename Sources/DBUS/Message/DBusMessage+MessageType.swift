extension DBusMessage {
  /// The type of a D-Bus message.
  ///
  /// D-Bus defines four types of messages that can be sent over a connection. Each message type
  /// serves a specific purpose in the D-Bus communication protocol.
  ///
  /// ## Message Flow
  ///
  /// The typical flow for method calls is:
  /// 1. Client sends a `methodCall` message
  /// 2. Server processes the call and responds with either:
  ///    - A `methodReturn` message containing the return values
  ///    - An `error` message if something went wrong
  ///
  /// Signals are broadcast messages that don't expect a reply.
  public enum MessageType: UInt8, Sendable {
    /// A method call message.
    ///
    /// Method calls are requests sent from a client to a service asking it to execute a specific method.
    /// They typically expect a reply (either a method return or an error), unless the `noReplyExpected`
    /// flag is set.
    ///
    /// Required header fields: path, member (method name)
    /// Optional header fields: interface, destination
    case methodCall = 1

    /// A method return message.
    ///
    /// Method returns are sent in response to method calls and contain the return values from the
    /// called method. They must include a `replySerial` header field that matches the serial number
    /// of the original method call.
    ///
    /// Required header fields: replySerial
    case methodReturn = 2

    /// An error message.
    ///
    /// Error messages are sent in response to method calls when something goes wrong. They contain
    /// an error name (like a exception type) and optional error details in the message body.
    ///
    /// Required header fields: errorName, replySerial
    case error = 3

    /// A signal message.
    ///
    /// Signals are broadcast messages that notify interested parties about events. Unlike method calls,
    /// signals don't expect a reply. They're used for notifications like "property changed" or
    /// "device added".
    ///
    /// Required header fields: path, interface, member (signal name)
    case signal = 4
  }
}
