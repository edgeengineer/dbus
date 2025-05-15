enum DBusError: Error {
  case earlyEOF
  case invalidByteOrder
  case invalidMessageType
  case invalidHeader
  case truncatedHeaderFields
  case invalidHeaderField
  case invalidString
  case invalidUTF8
  case invalidSignature
  case unsupportedType
  case truncatedBody
}
