import NIOCore

struct DBusString {
    static func read(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
        let length = try buffer.requireInteger(endianness: byteOrder) as UInt32
        let bytes = try buffer.requireBytes(length: Int(length))
        guard buffer.readInteger(as: UInt8.self) == 0 else { throw DBusError.invalidString }
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw DBusError.invalidUTF8
        }
        return string
    }

    static func readSignature(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
        let length = try buffer.requireInteger() as UInt8
        let bytes = try buffer.requireBytes(length: Int(length))
        guard buffer.readInteger(as: UInt8.self) == 0 else {
            throw DBusError.invalidSignature
        }
        guard let string = String(bytes: bytes, encoding: .ascii) else {
            throw DBusError.invalidUTF8
        }
        return string
    }
}