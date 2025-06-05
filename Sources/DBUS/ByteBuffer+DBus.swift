import NIO

extension ByteBuffer {
  @discardableResult
  mutating func alignReader(to alignment: Int) -> Int {
    let misalignment = self.readerIndex % alignment
    if misalignment == 0 {
      return 0
    }
    let padding = alignment - misalignment
    self.moveReaderIndex(forwardBy: padding)
    return padding
  }

  mutating func alignWriter(to alignment: Int) {
    let padding = (alignment - (self.writerIndex % alignment)) % alignment
    if padding > 0 {
      self.writeRepeatingByte(0, count: padding)
    }
  }

  mutating func requireInteger<T: FixedWidthInteger>(endianness: Endianness = .little) throws -> T {
    guard let value: T = self.readInteger(endianness: endianness) else {
      throw DBusError.invalidHeader
    }
    return value
  }

  mutating func requireDouble(endianness: Endianness = .little) throws -> Double {
    guard
      let value: UInt64 = self.readInteger(endianness: endianness)
    else {
      throw DBusError.invalidHeader
    }
    return Double(bitPattern: value)
  }

  mutating func requireBytes(length: Int) throws -> [UInt8] {
    guard let bytes = self.readBytes(length: length) else {
      throw DBusError.invalidHeader
    }
    return bytes
  }

  mutating func requireSlice(length: Int) throws -> ByteBuffer {
    guard let slice = self.readSlice(length: length) else {
      throw DBusError.invalidHeader
    }
    return slice
  }
}
