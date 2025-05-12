// D-Bus Type Signature Parser for SwiftNIO-only implementation
// No Foundation usage

public struct DBusTypeSignature {
    public let types: [DBusType]
    public let raw: String

    public init(_ signature: String) throws {
        self.raw = signature
        var parser = Parser(signature)
        self.types = try parser.parseAll()
        if !parser.isAtEnd {
            throw Error.extraCharacters
        }
    }

    // MARK: - Parser
    internal struct Parser {
        let signature: String
        var index: String.Index
        var isAtEnd: Bool { index == signature.endIndex }

        init(_ signature: String) {
            self.signature = signature
            self.index = signature.startIndex
        }

        mutating func parseAll() throws -> [DBusType] {
            var result: [DBusType] = []
            while !isAtEnd {
                result.append(try parseType())
            }
            return result
        }

        mutating func parseType() throws -> DBusType {
            guard !isAtEnd else { throw Error.unexpectedEnd }
            let c = signature[index]
            index = signature.index(after: index)
            switch c {
            case "y": return .byte
            case "b": return .boolean
            case "n": return .int16
            case "q": return .uint16
            case "i": return .int32
            case "u": return .uint32
            case "x": return .int64
            case "t": return .uint64
            case "d": return .double
            case "s": return .string
            case "o": return .objectPath
            case "g": return .signature
            case "h": return .unixFd
            case "v": return .variant
            case "a":
                let element = try parseType()
                return .array(element)
            case "(":
                var fields: [DBusType] = []
                while !isAtEnd, signature[index] != ")" {
                    fields.append(try parseType())
                }
                guard !isAtEnd, signature[index] == ")" else { throw Error.unmatchedParenthesis }
                index = signature.index(after: index)
                return .structure(fields)
            case "{":
                let key = try parseType()
                let value = try parseType()
                guard !isAtEnd, signature[index] == "}" else { throw Error.unmatchedBrace }
                index = signature.index(after: index)
                return .dictEntry(key: key, value: value)
            default:
                throw Error.invalidTypeChar(c)
            }
        }
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedEnd
        case unmatchedParenthesis
        case unmatchedBrace
        case invalidTypeChar(Character)
        case extraCharacters

        public var description: String {
            switch self {
            case .unexpectedEnd: return "Unexpected end of signature string."
            case .unmatchedParenthesis: return "Unmatched parenthesis in signature."
            case .unmatchedBrace: return "Unmatched brace in signature."
            case .invalidTypeChar(let c): return "Invalid type character: \(c.utf8)"
            case .extraCharacters: return "Extra characters after valid signature."
            }
        }
    }
} 