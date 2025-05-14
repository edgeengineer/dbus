import NIOCore

struct DBusString {
    static func read(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
        // Check if we have enough bytes for the length
        guard buffer.readableBytes >= 4 else {
            throw DBusError.invalidString
        }
        
        let length = try buffer.requireInteger(endianness: byteOrder) as UInt32
        
        // Check if we have enough bytes for the string data plus null terminator
        guard buffer.readableBytes >= Int(length) + 1 else {
            throw DBusError.invalidString
        }
        
        let bytes = try buffer.requireBytes(length: Int(length))
        
        // Check for null terminator
        guard let nullTerminator = buffer.readInteger(as: UInt8.self), nullTerminator == 0 else {
            throw DBusError.invalidString
        }
        
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw DBusError.invalidUTF8
        }
        
        return string
    }

    static func readSignature(from buffer: inout ByteBuffer, byteOrder: Endianness) throws -> String {
        // Check if we have enough bytes for the length
        guard buffer.readableBytes >= 1 else {
            throw DBusError.invalidSignature
        }
        
        let length = try buffer.requireInteger() as UInt8
        
        // Check if we have enough bytes for the signature data plus null terminator
        guard buffer.readableBytes >= Int(length) + 1 else {
            throw DBusError.invalidSignature
        }
        
        let bytes = try buffer.requireBytes(length: Int(length))
        
        // Check for null terminator
        guard let nullTerminator = buffer.readInteger(as: UInt8.self), nullTerminator == 0 else {
            throw DBusError.invalidSignature
        }
        
        guard let string = String(bytes: bytes, encoding: .ascii) else {
            throw DBusError.invalidUTF8
        }
        
        return string
    }
}