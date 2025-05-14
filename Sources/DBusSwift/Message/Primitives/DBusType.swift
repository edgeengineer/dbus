/// Represents D-Bus data types as defined in the D-Bus Specification.
///
/// D-Bus has a well-defined type system used for serializing data in messages.
/// Each type has specific alignment requirements and wire format.
///
/// Reference: https://dbus.freedesktop.org/doc/dbus-specification.html#type-system
public enum DBusType {
    case byte
    case boolean
    case int16
    case uint16
    case int32
    case uint32
    case int64
    case uint64
    case double
    case string
    case objectPath
    case signature
    case unixFd
    indirect case array(DBusType)
    indirect case dictEntry(key: DBusType, value: DBusType)
    case structure([DBusType])
    case variant

    /// The alignment requirement for each type in bytes.
    /// 
    /// According to the D-Bus specification, each data type has specific alignment
    /// requirements when marshalling data. This property returns the number of bytes
    /// to which a value of the given type must be aligned.
    ///
    /// Reference: https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling-alignment
    var alignment: Int {
        switch self {
        case .byte: return 1
        case .boolean: return 4  // BOOLEAN is aligned to 4 bytes according to the spec
        case .int16: return 2
        case .uint16: return 2
        case .int32: return 4
        case .uint32: return 4
        case .int64: return 8
        case .uint64: return 8
        case .double: return 8
        case .string: return 4
        case .objectPath: return 4
        case .signature: return 1
        case .unixFd: return 4
        case .array: return 4
        case .dictEntry: return 8
        case .structure: return 8
        case .variant: return 1
        }
    }
}