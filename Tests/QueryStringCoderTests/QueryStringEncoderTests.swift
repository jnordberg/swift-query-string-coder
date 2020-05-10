import QueryStringCoder
import XCTest

final class QueryStringEncoderTests: XCTestCase {
    func AssertEncodes<T: Encodable>(_ encoder: QueryStringEncoder, _ value: T, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        let result: String
        do {
            result = try encoder.encode(value)
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
            return
        }
        XCTAssertEqual(result, expected, file: file, line: line)
    }

    func testEncodes() throws {
        struct MyQuery: Codable {
            let hello: String
            let tags: [String]
            let flag: Bool
        }
        let e = QueryStringEncoder()
        AssertEncodes(e, MyQuery(hello: "world", tags: [], flag: false), "hello=world")
        AssertEncodes(e, MyQuery(hello: "world", tags: ["foo", "bar"], flag: true), "hello=world&tags=foo&tags=bar&flag")
    }

    func testSortedKeys() throws {
        struct MyQuery: Codable {
            let xa = 123
            let alice: Float64 = 1.0123456789
            let bob = Int64.min
            let yogi: [Int8] = [1, 2, 3]
            let _q = "foo"
        }
        let e = QueryStringEncoder()
        AssertEncodes(e, MyQuery(), "xa=123&alice=1.0123456789&bob=-9223372036854775808&yogi=1&yogi=2&yogi=3&_q=foo")
        e.outputFormatting = .sortedKeys
        AssertEncodes(e, MyQuery(), "_q=foo&alice=1.0123456789&bob=-9223372036854775808&xa=123&yogi=1&yogi=2&yogi=3")
    }

    func testKeyEncodingStrategy() throws {
        struct MyQuery: Codable {
            let PascalCase = 1
            let camelCase = 2
            let snake_case = 3
        }
        let e = QueryStringEncoder()
        AssertEncodes(e, MyQuery(), "PascalCase=1&camelCase=2&snake_case=3")
        e.keyEncodingStrategy = .convertToSnakeCase
        AssertEncodes(e, MyQuery(), "pascal_case=1&camel_case=2&snake_case=3")
        e.keyEncodingStrategy = .custom { $0.uppercased() }
        AssertEncodes(e, MyQuery(), "PASCALCASE=1&CAMELCASE=2&SNAKE_CASE=3")
    }

    func testEncodig() throws {
        struct MyQuery: Codable {
            let a = "foo=bar&smile=😊😄"
            let b = "\\/#fragment"

            enum CodingKeys: String, CodingKey {
                case a = "❤️"
                case b = "b™"
            }
        }
        let e = QueryStringEncoder()
        AssertEncodes(e, MyQuery(), "%E2%9D%A4%EF%B8%8F=foo%3Dbar%26smile%3D%F0%9F%98%8A%F0%9F%98%84&b%E2%84%A2=%5C/%23fragment")
    }
}
