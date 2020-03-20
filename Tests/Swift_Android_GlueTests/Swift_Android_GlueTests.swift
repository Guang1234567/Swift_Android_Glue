import XCTest
@testable import Swift_Android_Glue

final class Swift_Android_GlueTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Swift_Android_Glue().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
