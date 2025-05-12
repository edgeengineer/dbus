import NIOCore

public struct DBusVariant: Sendable, Hashable {
    public let signature: String
    public let value: DBusValue

    internal init(typeSignature: String, value: DBusValue) {
        self.signature = typeSignature
        self.value = value
    }

    public init(_ value: DBusValue) {
        self.signature = value.dbusTypeSignature
        self.value = value
    }

    init(from buffer: inout ByteBuffer, byteOrder: Endianness) throws {
        self.signature = try DBusString.readSignature(from: &buffer, byteOrder: byteOrder)
        self.value = try DBusValue.parse(from: &buffer, typeSignature: signature, byteOrder: byteOrder)
    }
}


extension DBusVariant {
    func write(to buffer: inout ByteBuffer, byteOrder: Endianness) {
        // Write signature
        if let sig = value.dbusTypeSignature.first {
            buffer.writeInteger(UInt8(1))
            buffer.writeInteger(UInt8(sig.utf8.first!))
            buffer.writeInteger(UInt8(0))
        }
        value.write(to: &buffer, byteOrder: byteOrder)
    }
}