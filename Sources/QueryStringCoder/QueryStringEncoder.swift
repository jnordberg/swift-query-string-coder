import Foundation

public final class QueryStringEncoder {
    static let allowedCharacters = CharacterSet.urlQueryAllowed.subtracting(["=", "?", "&"])

    public enum KeyEncodingStrategy {
        case useDefaultKeys
        case convertToSnakeCase
        case custom((String) -> String)
    }

    public struct OutputFormatting: OptionSet {
        public let rawValue: UInt
        public static let sortedKeys = OutputFormatting(rawValue: 1 << 0)
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }

    public var keyEncodingStrategy = KeyEncodingStrategy.useDefaultKeys
    public var outputFormatting: OutputFormatting = []

    public init() {}

    public func encode<T>(_ value: T) throws -> String where T: Encodable {
        let encoder = QueryStringEncoder.Encoder()
        try value.encode(to: encoder)

        let transformKey: (String) -> String
        switch keyEncodingStrategy {
        case .useDefaultKeys:
            transformKey = { $0 }
        case .convertToSnakeCase:
            transformKey = camel2snake
        case let .custom(fn):
            transformKey = fn
        }

        let encodeValue = { (val: String) in val.addingPercentEncoding(withAllowedCharacters: Self.allowedCharacters) ?? "" }

        var parts = encoder.parts
            .map { part in
                (
                    key: encodeValue(transformKey(part.key.stringValue)),
                    value: encodeValue(part.value)
                )
            }
            .filter { part in
                !part.key.isEmpty
            }

        if outputFormatting.contains(.sortedKeys) {
            parts.sort { a, b in
                a.key < b.key
            }
        }

        return parts.compactMap { part in
            guard !part.value.isEmpty else {
                return part.key
            }
            return part.key + "=" + part.value
        }.joined(separator: "&")
    }
}

private protocol QueryStringPart {
    var key: CodingKey { get }
    var value: String { get }
}

private extension QueryStringEncoder {
    struct Single: QueryStringPart {
        let key: CodingKey
        var value: String { "" }
        init(_ key: CodingKey) { self.key = key }
    }

    struct Pair: QueryStringPart {
        let key: CodingKey
        let value: String

        init(_ key: CodingKey, _ value: String) {
            self.key = key
            self.value = value
        }
    }

    struct AnyCodingKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(_ value: String) {
            stringValue = value
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue _: Int) {
            nil
        }
    }

    class Encoder: Swift.Encoder {
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        var parts: [QueryStringPart] = []
        var lastKey: CodingKey = AnyCodingKey("undefined")

        func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            KeyedEncodingContainer(KeyedContainer<Key>(self))
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            Container(self, lastKey)
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            Container(self, lastKey)
        }

        func push(_ key: CodingKey) {
            lastKey = key
            parts.append(Single(key))
        }

        func push(_ key: CodingKey, _ value: String) {
            lastKey = key
            parts.append(Pair(key, value))
        }
    }

    struct Container: SingleValueEncodingContainer, UnkeyedEncodingContainer {
        var codingPath: [CodingKey] = []
        var count: Int = 0
        var encoder: Encoder
        var key: CodingKey

        init(_ encoder: Encoder, _ key: CodingKey) {
            self.encoder = encoder
            self.key = key
        }

        mutating func encodeNil() throws {}

        mutating func encode(_ value: Bool) throws {
            if value { encoder.push(key) }
        }

        mutating func encode(_ value: String) throws {
            encoder.push(key, value)
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable & LosslessStringConvertible {
            encoder.push(key, String(value))
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            encoder.push(key, String(describing: value))
        }

        mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            encoder.unkeyedContainer()
        }

        mutating func superEncoder() -> Swift.Encoder {
            encoder
        }
    }

    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        mutating func superEncoder() -> Swift.Encoder {
            encoder
        }

        mutating func superEncoder(forKey _: Key) -> Swift.Encoder {
            encoder
        }

        var codingPath: [CodingKey] = []
        var encoder: Encoder

        init(_ encoder: Encoder) {
            self.encoder = encoder
        }

        mutating func encodeNil(forKey _: Key) throws {}

        mutating func encode(_ value: Bool, forKey key: Key) throws {
            if value { encoder.push(key) }
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            encoder.lastKey = key
            try value.encode(to: encoder)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.lastKey = key
            return encoder.container(keyedBy: keyType)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            encoder.lastKey = key
            return encoder.unkeyedContainer()
        }
    }
}
