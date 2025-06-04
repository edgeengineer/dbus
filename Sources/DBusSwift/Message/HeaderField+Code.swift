extension HeaderField {
  /// Header field codes defined by the D-Bus specification.
  ///
  /// Each code identifies a specific type of metadata that can be included in a message header.
  /// Different message types have different requirements for which header fields must be present.
  public enum Code: UInt8, Sendable {
    /// The object path the message is being sent to or from.
    ///
    /// Required for: method calls, signals
    /// Value type: Object path string (e.g., "/org/freedesktop/DBus")
    case path = 1

    /// The interface the method or signal belongs to.
    ///
    /// Required for: signals
    /// Optional for: method calls (but recommended)
    /// Value type: Interface name string (e.g., "org.freedesktop.DBus")
    case interface = 2

    /// The name of the method or signal.
    ///
    /// Required for: method calls, signals
    /// Value type: Member name string (e.g., "ListNames")
    case member = 3

    /// The name of the error (for error messages).
    ///
    /// Required for: error messages
    /// Value type: Error name string (e.g., "org.freedesktop.DBus.Error.Failed")
    case errorName = 4

    /// The serial number of the message this is a reply to.
    ///
    /// Required for: method returns, error messages
    /// Value type: UInt32
    case replySerial = 5

    /// The bus name of the intended recipient.
    ///
    /// Optional but common for method calls
    /// Value type: Bus name string (e.g., "org.freedesktop.DBus" or ":1.42")
    case destination = 6

    /// The unique bus name of the sending connection.
    ///
    /// Automatically added by the message bus
    /// Value type: Unique bus name string (e.g., ":1.42")
    case sender = 7

    /// The type signature of the message body.
    ///
    /// Required if the message has a body, must be omitted if empty
    /// Value type: Signature string (e.g., "si" for string + int32)
    case signature = 8

    /// The number of Unix file descriptors that accompany the message.
    ///
    /// Required when sending file descriptors (Linux only)
    /// Value type: UInt32
    case unixFds = 9
  }
}
