import NIOCore

public indirect enum DBusValue: Hashable, Sendable {
    case byte(UInt8)
    case boolean(Bool)
    case int16(Int16)
    case uint16(UInt16)
    case int32(Int32)
    case uint32(UInt32)
    case int64(Int64)
    case uint64(UInt64)
    case double(Double)
    case string(String)
    case objectPath(String)
    case signature(String)
    case unixFd(UInt32)
    case variant(DBusVariant)
    case array([DBusValue])
    case structure([DBusValue])
    case dictionary([DBusValue: DBusValue])

    // Returns the required alignment for a D-Bus type signature character
    static func alignment(for typeSignature: String) -> Int {
        guard let c = typeSignature.first else { return 1 }
        switch c {
        case "y": return 1 // BYTE
        case "b", "n", "q": return 2 // BOOLEAN, INT16, UINT16
        case "i", "u", "s", "o", "g", "h": return 4 // INT32, UINT32, STRING, OBJECT_PATH, SIGNATURE, UNIX_FD
        case "x", "t", "d": return 8 // INT64, UINT64, DOUBLE
        case "a": return 4 // ARRAY
        case "(": return 8 // STRUCT
        case "{": return 8 // DICT_ENTRY
        case "v": return 1 // VARIANT (signature is 1, value is aligned as per type)
        default: return 1
        }
    }

    static func parse(from buffer: inout ByteBuffer, typeSignature: String, byteOrder: Endianness)
    throws -> DBusValue
    {
        guard let typeChar = typeSignature.first else {
            throw DBusError.invalidSignature
        }
        // Align buffer before reading value
        let alignment = alignment(for: typeSignature)
        buffer.alignReader(to: alignment)
        switch typeChar {
        case "y": return .byte(try buffer.requireInteger())
        case "b": return .boolean(try buffer.requireInteger(endianness: byteOrder) != 0)
        case "n": return .int16(try buffer.requireInteger(endianness: byteOrder))
        case "q": return .uint16(try buffer.requireInteger(endianness: byteOrder))
        case "i": return .int32(try buffer.requireInteger(endianness: byteOrder))
        case "u": return .uint32(try buffer.requireInteger(endianness: byteOrder))
        case "x": return .int64(try buffer.requireInteger(endianness: byteOrder))
        case "t": return .uint64(try buffer.requireInteger(endianness: byteOrder))
        case "d": return .double(try buffer.requireDouble(endianness: byteOrder))
        case "s": return .string(try DBusString.read(from: &buffer, byteOrder: byteOrder))
        case "o": return .objectPath(try DBusString.read(from: &buffer, byteOrder: byteOrder))
        case "g": return .signature(try DBusString.readSignature(from: &buffer, byteOrder: byteOrder))
        case "h": return .unixFd(try buffer.requireInteger(endianness: byteOrder))
        case "v": return .variant(try DBusVariant(from: &buffer, byteOrder: byteOrder))
        case "a":
            let elementSig = String(typeSignature.dropFirst())
            let arrayLen = try buffer.requireInteger(endianness: byteOrder) as UInt32
            buffer.alignReader(to: 4)
            var arrayBuf = try buffer.requireSlice(length: Int(arrayLen))
            if elementSig.starts(with: "{") {
                let inner = String(elementSig.dropFirst().dropLast())
                var dict: [DBusValue: DBusValue] = [:]
                while arrayBuf.readableBytes > 0 {
                    arrayBuf.alignReader(to: 8)
                    let key = try DBusValue.parse(
                        from: &arrayBuf, typeSignature: String(inner.prefix(1)), byteOrder: byteOrder)
                    let value = try DBusValue.parse(
                        from: &arrayBuf,
                        typeSignature: String(inner.suffix(from: inner.index(inner.startIndex, offsetBy: 1))),
                        byteOrder: byteOrder)
                    dict[key] = value
                }
                return .dictionary(dict)
            } else {
                var elements: [DBusValue] = []
                while arrayBuf.readableBytes > 0 {
                    elements.append(
                        try DBusValue.parse(from: &arrayBuf, typeSignature: elementSig, byteOrder: byteOrder))
                }
                return .array(elements)
            }
        case "(":
            var inner = String(typeSignature.dropFirst().dropLast())
            var fields: [DBusValue] = []
            while !inner.isEmpty {
                let typeChar = String(inner.removeFirst())
                fields.append(
                    try DBusValue.parse(from: &buffer, typeSignature: typeChar, byteOrder: byteOrder))
            }
            buffer.alignReader(to: 8)
            return .structure(fields)
        default:
            throw DBusError.unsupportedType
        }
    }
}

extension DBusValue {
    func write(to buffer: inout ByteBuffer, byteOrder: Endianness) {
        switch self {
        case .byte(let v):
            buffer.writeInteger(v)
        case .boolean(let v):
            buffer.alignWriter(to: 4)
            buffer.writeInteger(v ? UInt32(1) : UInt32(0), endianness: byteOrder)
        case .int16(let v):
            buffer.alignWriter(to: 2)
            buffer.writeInteger(v, endianness: byteOrder)
        case .uint16(let v):
            buffer.alignWriter(to: 2)
            buffer.writeInteger(v, endianness: byteOrder)
        case .int32(let v):
            buffer.alignWriter(to: 4)
            buffer.writeInteger(v, endianness: byteOrder)
        case .uint32(let v):
            buffer.alignWriter(to: 4)
            buffer.writeInteger(v, endianness: byteOrder)
        case .int64(let v):
            buffer.alignWriter(to: 8)
            buffer.writeInteger(v, endianness: byteOrder)
        case .uint64(let v):
            buffer.alignWriter(to: 8)
            buffer.writeInteger(v, endianness: byteOrder)
        case .double(let v):
            buffer.alignWriter(to: 8)
            buffer.writeInteger(v.bitPattern, endianness: byteOrder)
        case .string(let s):
            buffer.alignWriter(to: 4)
            let bytes = Array(s.utf8)
            buffer.writeInteger(UInt32(bytes.count), endianness: byteOrder)
            buffer.writeBytes(bytes)
            buffer.writeInteger(UInt8(0))
        case .objectPath(let s):
            buffer.alignWriter(to: 4)
            let bytes = Array(s.utf8)
            buffer.writeInteger(UInt32(bytes.count), endianness: byteOrder)
            buffer.writeBytes(bytes)
            buffer.writeInteger(UInt8(0))
        case .signature(let s):
            buffer.writeInteger(UInt8(s.utf8.count))
            buffer.writeBytes(Array(s.utf8))
            buffer.writeInteger(UInt8(0))
        case .unixFd(let v):
            buffer.alignWriter(to: 4)
            buffer.writeInteger(v, endianness: byteOrder)
        case .variant(let v):
            v.write(to: &buffer, byteOrder: byteOrder)
        case .array(let arr):
            buffer.alignWriter(to: 4)
            let start = buffer.writerIndex
            buffer.writeInteger(UInt32(0), endianness: byteOrder) // Placeholder for length
            let align = arr.first.map { DBusValue.alignment(for: $0.dbusTypeSignature) } ?? 1
            buffer.alignWriter(to: align)
            let arrayStart = buffer.writerIndex
            for el in arr {
                el.write(to: &buffer, byteOrder: byteOrder)
            }
            let arrayEnd = buffer.writerIndex
            let len = UInt32(arrayEnd - arrayStart)
            buffer.setInteger(len, at: start, endianness: byteOrder)
        case .structure(let fields):
            buffer.alignWriter(to: 8)
            for f in fields {
                f.write(to: &buffer, byteOrder: byteOrder)
            }
        case .dictionary(let dict):
            buffer.alignWriter(to: 4)
            let start = buffer.writerIndex
            buffer.writeInteger(UInt32(0), endianness: byteOrder) // Placeholder for length
            buffer.alignWriter(to: 8)
            let dictStart = buffer.writerIndex
            for (k, v) in dict {
                buffer.alignWriter(to: 8)
                k.write(to: &buffer, byteOrder: byteOrder)
                v.write(to: &buffer, byteOrder: byteOrder)
            }
            let dictEnd = buffer.writerIndex
            let len = UInt32(dictEnd - dictStart)
            buffer.setInteger(len, at: start, endianness: byteOrder)
        }
    }

    // Helper to get the D-Bus type signature for a value
    var dbusTypeSignature: String {
        switch self {
        case .byte: return "y"
        case .boolean: return "b"
        case .int16: return "n"
        case .uint16: return "q"
        case .int32: return "i"
        case .uint32: return "u"
        case .int64: return "x"
        case .uint64: return "t"
        case .double: return "d"
        case .string: return "s"
        case .objectPath: return "o"
        case .signature: return "g"
        case .unixFd: return "h"
        case .variant: return "v"
        case .array(let arr):
            return "a" + (arr.first?.dbusTypeSignature ?? "?")
        case .structure(let fields):
            return "(" + fields.map { $0.dbusTypeSignature }.joined() + ")"
        case .dictionary(let dict):
            if let (k, v) = dict.first {
                return "a{" + k.dbusTypeSignature + v.dbusTypeSignature + "}"
            } else {
                return "a{??}"
            }
        }
    }
}