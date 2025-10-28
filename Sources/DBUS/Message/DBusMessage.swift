import NIOCore

public struct DBusRequest: Sendable {
  /// The byte order used for encoding numeric values in this message.
  public var byteOrder: Endianness

  /// The type of this message (method call, method return, error, or signal).
  public var messageType: DBusMessage.MessageType

  /// Flags that modify the behavior of this message.
  public var flags: DBusMessage.Flags

  /// The D-Bus protocol version (typically 1).
  public var protocolVersion: UInt8

  /// Header fields containing metadata about the message.
  ///
  /// Common header fields include destination, path, interface, member, and signature.
  public var headerFields: [HeaderField]

  /// The message body containing the actual data payload.
  ///
  /// The body is an array of ``DBusValue`` instances that represent the arguments or return values of the message.
  public var body: [DBusValue]

  /// Creates a D-Bus method call message.
  ///
  /// This is the primary way to create messages for invoking methods on D-Bus services.
  ///
  /// - Parameters:
  ///   - destination: The bus name of the service to send the message to (e.g., "org.freedesktop.DBus").
  ///   - path: The object path of the target object (e.g., "/org/freedesktop/DBus").
  ///   - interface: The interface containing the method (e.g., "org.freedesktop.DBus").
  ///   - method: The name of the method to call (e.g., "ListNames").
  ///   - serial: A unique serial number for this message.
  ///   - body: An array of ``DBusValue`` instances representing the method arguments. Defaults to empty.
  ///   - flags: Message flags to set. Defaults to no flags.
  ///
  /// - Returns: A configured ``DBusMessage`` ready to be sent.
  ///
  /// ## Example
  /// ```swift
  /// let message = DBusMessage.createMethodCall(
  ///     destination: "org.freedesktop.DBus",
  ///     path: "/org/freedesktop/DBus",
  ///     interface: "org.freedesktop.DBus",
  ///     method: "ListNames",
  ///     serial: 1
  /// )
  /// ```
  public static func createMethodCall(
    destination: String,
    path: String,
    interface: String,
    method: String,
    body: [DBusValue] = [],
    flags: DBusMessage.Flags = []
  ) -> DBusRequest {
    var headerFields = [
      HeaderField(
        code: .destination,
        variant: DBusVariant(.string(destination))
      ),
      HeaderField(
        code: .path,
        variant: DBusVariant(.objectPath(path))
      ),
      HeaderField(
        code: .interface,
        variant: DBusVariant(.string(interface))
      ),
      HeaderField(
        code: .member,
        variant: DBusVariant(.string(method))
      ),
    ]

    if !body.isEmpty {
      headerFields.append(
        HeaderField(
          code: .signature,
          variant: DBusVariant(
            .signature(body.map(\.dbusTypeSignature).joined())
          )
        )
      )
    }

    return DBusRequest(
      byteOrder: .host,
      messageType: .methodCall,
      flags: flags,
      protocolVersion: 1,
      headerFields: headerFields,
      body: body
    )
  }
}

/// A D-Bus message that can be sent or received over a D-Bus connection.
///
/// `DBusMessage` represents the fundamental unit of communication in D-Bus. Each message has a type
/// (method call, method return, error, or signal), header fields containing metadata, and an optional body
/// containing the message payload.
///
/// ## Topics
///
/// ### Creating Messages
///
/// The most common way to create a message is using the static factory method:
/// - ``createMethodCall(destination:path:interface:method:serial:body:flags:)``
///
/// ### Message Properties
///
/// - ``byteOrder``: The byte order used for encoding numeric values
/// - ``messageType``: The type of message (method call, return, error, or signal)
/// - ``flags``: Message flags that modify behavior
/// - ``protocolVersion``: The D-Bus protocol version (typically 1)
/// - ``serial``: Unique identifier for this message
/// - ``headerFields``: Array of header fields containing metadata
/// - ``body``: Array of values forming the message payload
/// - ``replyTo``: Serial number of the message this is replying to (if applicable)
public struct DBusMessage: Sendable {
  /// The byte order used for encoding numeric values in this message.
  public var byteOrder: Endianness

  /// The type of this message (method call, method return, error, or signal).
  public var messageType: MessageType

  /// Flags that modify the behavior of this message.
  public var flags: Flags

  /// The D-Bus protocol version (typically 1).
  public var protocolVersion: UInt8

  /// A unique serial number identifying this message.
  ///
  /// Serial numbers are used to match method returns and errors with their corresponding method calls.
  public var serial: UInt32

  /// Header fields containing metadata about the message.
  ///
  /// Common header fields include destination, path, interface, member, and signature.
  public var headerFields: [HeaderField]

  /// The message body containing the actual data payload.
  ///
  /// The body is an array of ``DBusValue`` instances that represent the arguments or return values of the message.
  public var body: [DBusValue]

  /// The serial number of the message this message is replying to, if applicable.
  ///
  /// This property extracts the reply serial from the header fields. It returns `nil` for messages
  /// that are not replies (such as method calls or signals).
  public var replyTo: UInt32? {
    guard
      case .uint32(let replyTo) = headerFields.first(where: { $0.code == .replySerial })?.variant
        .value
    else {
      return nil
    }
    return replyTo
  }

  private static func readValue(
    from buffer: inout ByteBuffer,
    type: DBusType,
    byteOrder: Endianness
  ) throws -> DBusValue {
    buffer.alignReader(to: type.alignment)
    switch type {
    case .byte:
      return .byte(try buffer.requireInteger(endianness: byteOrder))
    case .boolean:
      return .boolean(try buffer.requireInteger(endianness: byteOrder) != 0 as UInt8)
    case .int16:
      return .int16(try buffer.requireInteger(endianness: byteOrder))
    case .uint16:
      return .uint16(try buffer.requireInteger(endianness: byteOrder))
    case .int32:
      return .int32(try buffer.requireInteger(endianness: byteOrder))
    case .uint32:
      return .uint32(try buffer.requireInteger(endianness: byteOrder))
    case .int64:
      return .int64(try buffer.requireInteger(endianness: byteOrder))
    case .uint64:
      return .uint64(try buffer.requireInteger(endianness: byteOrder))
    case .double:
      return .double(try buffer.requireDouble(endianness: byteOrder))
    case .string:
      let value = try DBusString.read(from: &buffer, byteOrder: byteOrder)
      return .string(value)
    case .objectPath:
      let value = try DBusString.read(from: &buffer, byteOrder: byteOrder)
      return .objectPath(value)
    case .signature:
      let value = try DBusString.readSignature(from: &buffer, byteOrder: byteOrder)
      return .signature(value)
    case .unixFd:
      return .unixFd(try buffer.requireInteger(endianness: byteOrder))
    case .array(let elementType):
      let byteLength = try buffer.requireInteger(endianness: byteOrder) as UInt32
      let readerIndex = buffer.readerIndex
      let endReaderIndex = readerIndex + Int(byteLength)
      var values: [DBusValue] = []

      while buffer.readerIndex < endReaderIndex {
        buffer.alignReader(to: elementType.alignment)
        let value = try Self.readValue(from: &buffer, type: elementType, byteOrder: byteOrder)
        values.append(value)
      }

      return .array(values)
    case .dictEntry(let keyType, let valueType):
      let key = try Self.readValue(from: &buffer, type: keyType, byteOrder: byteOrder)
      let value = try Self.readValue(from: &buffer, type: valueType, byteOrder: byteOrder)
      return .dictionary([key: value])
    case .structure(let types):
      var values: [DBusValue] = []
      for type in types {
        let value = try Self.readValue(from: &buffer, type: type, byteOrder: byteOrder)
        values.append(value)
      }
      return .structure(values)
    case .variant:
      guard
        let typeLength = buffer.readInteger(as: UInt8.self),
        let typeCharacter = buffer.readString(length: Int(typeLength)),
        buffer.readInteger(as: UInt8.self) == 0
      else {
        throw DBusError.invalidHeader
      }

      var typeParser = DBusTypeSignature.Parser(typeCharacter)
      let type = try typeParser.parseType()
      guard typeParser.isAtEnd else {
        throw DBusError.invalidHeader
      }
      let value = try Self.readValue(from: &buffer, type: type, byteOrder: byteOrder)
      return .variant(DBusVariant(typeSignature: typeCharacter, value: value))
    }
  }

  private static func parseArguments(
    from buffer: inout ByteBuffer,
    from signature: DBusTypeSignature,
    byteOrder: Endianness
  ) throws -> [DBusValue] {
    var values: [DBusValue] = []
    for type in signature.types {
      let value = try Self.readValue(from: &buffer, type: type, byteOrder: byteOrder)
      values.append(value)
    }
    return values
  }

  /// Parses message arguments from a byte buffer using the signature from header fields.
  ///
  /// This method extracts the signature from the header fields and uses it to parse the body buffer
  /// into an array of ``DBusValue`` instances.
  ///
  /// - Parameters:
  ///   - headerFields: The header fields containing the signature field.
  ///   - body: A mutable byte buffer containing the serialized message body.
  ///   - byteOrder: The byte order to use when parsing numeric values.
  ///
  /// - Returns: An array of ``DBusValue`` instances parsed from the body.
  /// - Throws: ``DBusError/invalidHeader`` if the signature field is missing or invalid.
  public static func parseArguments(
    headerFields: [HeaderField],
    body: inout ByteBuffer,
    byteOrder: Endianness
  ) throws -> [DBusValue] {
    guard let signatureField = headerFields.first(where: { $0.code == .signature }) else {
      if body.readableBytes == 0 {
        return []
      }
      throw DBusError.invalidHeader
    }

    guard case .signature(let sig) = signatureField.variant.value else {
      throw DBusError.invalidHeader
    }

    if sig.isEmpty {
      return []
    }

    var bufferCopy = body
    let signature = try DBusTypeSignature(sig)
    let result = try Self.parseArguments(from: &bufferCopy, from: signature, byteOrder: byteOrder)

    body = bufferCopy
    return result
  }

  internal init(
    byteOrder: Endianness,
    messageType: MessageType,
    flags: Flags,
    protocolVersion: UInt8,
    serial: UInt32,
    headerFields: [HeaderField],
    body: [DBusValue]
  ) {
    self.byteOrder = byteOrder
    self.messageType = messageType
    self.flags = flags
    self.protocolVersion = protocolVersion
    self.serial = serial
    self.headerFields = headerFields
    self.body = body
  }

  init(from buffer: inout ByteBuffer) throws {
    guard
      let orderByte: UInt8 = buffer.readInteger()
    else {
      throw DBusError.earlyEOF
    }
    let byteOrder: Endianness
    switch orderByte {
    case 0x6C: byteOrder = .little
    case 0x42: byteOrder = .big
    default:
      throw DBusError.invalidByteOrder
    }
    self.byteOrder = byteOrder

    guard let typeRaw: UInt8 = buffer.readInteger(),
      let messageType = MessageType(rawValue: typeRaw)
    else {
      throw DBusError.invalidMessageType
    }
    self.messageType = messageType

    guard let flagsRaw: UInt8 = buffer.readInteger(),
      let version: UInt8 = buffer.readInteger(),
      let bodyLength: UInt32 = buffer.readInteger(endianness: byteOrder),
      let serial: UInt32 = buffer.readInteger(endianness: byteOrder),
      let headerFieldsLength: UInt32 = buffer.readInteger(endianness: byteOrder)
    else {
      throw DBusError.invalidHeader
    }

    self.flags = Flags(rawValue: flagsRaw)
    self.protocolVersion = version
    self.serial = serial

    guard var headersBuffer = buffer.readSlice(length: Int(headerFieldsLength)) else {
      throw DBusError.truncatedHeaderFields
    }

    self.headerFields = []
    while headersBuffer.readableBytes > 0 {
      let field = try HeaderField(from: &headersBuffer, byteOrder: byteOrder)
      self.headerFields.append(field)
    }

    buffer.alignReader(to: 8)

    guard var body = buffer.readSlice(length: Int(bodyLength)) else {
      throw DBusError.truncatedBody
    }
    self.body = try Self.parseArguments(
      headerFields: headerFields, body: &body, byteOrder: byteOrder)
  }
}

extension DBusMessage {
  func write(to buffer: inout ByteBuffer) {
    precondition(buffer.writerIndex == 0, "Cannot write to a non-empty ByteBuffer")
    // Write byte order
    buffer.writeInteger(byteOrder == .little ? UInt8(0x6C) : UInt8(0x42))
    // Write message type
    buffer.writeInteger(messageType.rawValue)
    // Write flags
    buffer.writeInteger(flags.rawValue)
    // Write protocol version
    buffer.writeInteger(protocolVersion)
    // Write body length (placeholder, update later)
    let bodyLenPos = buffer.writerIndex
    buffer.writeInteger(UInt32(0), endianness: byteOrder)
    // Write serial
    buffer.writeInteger(serial, endianness: byteOrder)
    // Write header fields length (placeholder, update later)
    let headerLenPos = buffer.writerIndex
    buffer.writeInteger(UInt32(0), endianness: byteOrder)
    // Write header fields
    let headerStart = buffer.writerIndex
    for field in headerFields {
      field.write(to: &buffer, byteOrder: byteOrder)
    }
    let headerEnd = buffer.writerIndex
    let headerLen = UInt32(headerEnd - headerStart)
    // Patch header fields length
    buffer.setInteger(headerLen, at: headerLenPos, endianness: byteOrder)
    // Align to 8 for body
    buffer.alignWriter(to: 8)
    // Write body
    let bodyStart = buffer.writerIndex

    for value in body {
      value.write(to: &buffer, byteOrder: byteOrder)
    }

    let bodyEnd = buffer.writerIndex
    let bodyLen = UInt32(bodyEnd - bodyStart)
    // Patch body length
    buffer.setInteger(bodyLen, at: bodyLenPos, endianness: byteOrder)
  }

  package static func createMethodCall(
    destination: String,
    path: String,
    interface: String,
    method: String,
    serial: UInt32,
    body: [DBusValue] = [],
    flags: Flags = []
  ) -> DBusMessage {
    var headerFields = [
      HeaderField(
        code: .destination,
        variant: DBusVariant(.string(destination))
      ),
      HeaderField(
        code: .path,
        variant: DBusVariant(.objectPath(path))
      ),
      HeaderField(
        code: .interface,
        variant: DBusVariant(.string(interface))
      ),
      HeaderField(
        code: .member,
        variant: DBusVariant(.string(method))
      ),
    ]

    if !body.isEmpty {
      headerFields.append(
        HeaderField(
          code: .signature,
          variant: DBusVariant(
            .signature(body.map(\.dbusTypeSignature).joined())
          )
        )
      )
    }

    return DBusMessage(
      byteOrder: .host,
      messageType: .methodCall,
      flags: flags,
      protocolVersion: 1,
      serial: serial,
      headerFields: headerFields,
      body: body
    )
  }
}
