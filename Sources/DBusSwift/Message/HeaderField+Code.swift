extension HeaderField {
    public enum Code: UInt8, Sendable {
        case path = 1
        case interface = 2
        case member = 3
        case errorName = 4
        case replySerial = 5
        case destination = 6
        case sender = 7
        case signature = 8
        case unixFds = 9
    }
}