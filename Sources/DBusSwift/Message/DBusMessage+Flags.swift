extension DBusMessage {
  /// Flags that modify the behavior of a D-Bus message.
  ///
  /// Message flags are set in the message header and control various aspects of message processing
  /// and delivery. Multiple flags can be combined using the standard `OptionSet` operations.
  ///
  /// ## Example
  /// ```swift
  /// // Create a message that doesn't expect a reply
  /// let message = DBusMessage.createMethodCall(
  ///     destination: "org.example.Service",
  ///     path: "/org/example/Object",
  ///     interface: "org.example.Interface",
  ///     method: "Notify",
  ///     serial: 1,
  ///     flags: [.noReplyExpected]
  /// )
  ///
  /// // Combine multiple flags
  /// let flags: DBusMessage.Flags = [.noReplyExpected, .noAutoStart]
  /// ```
  public struct Flags: OptionSet, Sendable {
    /// The raw flag value.
    public let rawValue: UInt8

    /// Creates a new flag set from a raw value.
    ///
    /// - Parameter rawValue: The raw flag bits.
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }

    /// Indicates that the sender doesn't expect a reply to this message.
    ///
    /// When this flag is set, the receiving side should not send a method return or error message
    /// in response. This is useful for notifications or "fire and forget" messages where the sender
    /// doesn't need confirmation of delivery or processing.
    ///
    /// - Note: Even with this flag set, the message may still generate signals or other side effects.
    public static let noReplyExpected = Flags(rawValue: 0x1)
    
    /// Prevents auto-starting of services when sending this message.
    ///
    /// By default, if a message is sent to a service that isn't currently running, D-Bus may
    /// attempt to start that service automatically. Setting this flag prevents that behavior,
    /// causing the message to fail if the service isn't already running.
    ///
    /// This is useful when you want to check if a service is running without inadvertently starting it.
    public static let noAutoStart = Flags(rawValue: 0x2)
    
    /// Allows interactive authorization for this method call.
    ///
    /// When set, this flag indicates that the method call may trigger an interactive authorization
    /// dialog if required by the security policy. This is typically used for privileged operations
    /// that may require user confirmation.
    ///
    /// - Note: This flag is only meaningful for method call messages.
    public static let allowInteractiveAuthorization = Flags(rawValue: 0x4)
  }
}
