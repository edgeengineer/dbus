extension DBusMessage {
    public struct Flags: OptionSet, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let noReplyExpected = Flags(rawValue: 0x1)
        public static let noAutoStart = Flags(rawValue: 0x2)
        public static let allowInteractiveAuthorization = Flags(rawValue: 0x4)
    }
}