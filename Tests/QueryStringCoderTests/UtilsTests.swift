@testable import QueryStringCoder
import XCTest

final class UtilsTests: XCTestCase {
    func testCamelToSnake() throws {
        XCTAssertEqual(camel2snake("FooBarBaz"), "foo_bar_baz")
        XCTAssertEqual(camel2snake("fooBarBaz"), "foo_bar_baz")
        XCTAssertEqual(camel2snake("fooBar_Baz"), "foo_bar_baz")
        XCTAssertEqual(camel2snake("_FooBar"), "_foo_bar")
        XCTAssertEqual(camel2snake("__Foo_bar__"), "__foo_bar__")
        XCTAssertEqual(camel2snake("__Foo_Bar__"), "__foo_bar__")
        XCTAssertEqual(camel2snake("__FooBar__"), "__foo_bar__")
        XCTAssertEqual(camel2snake("__foo_bar__"), "__foo_bar__")
        XCTAssertEqual(camel2snake("Foo❤️Bar😊baz👍"), "foo❤️_bar😊baz👍")
    }
}
