extension DBusMessage {
  public enum MessageType: UInt8, Sendable {
    case methodCall = 1
    case methodReturn = 2
    case error = 3
    case signal = 4
  }
}
