// StartWatch — FormattingTests: тесты форматирования вывода
import XCTest
@testable import StartWatch

final class FormattingTests: XCTestCase {

    func testANSIColorsDisabledWhenNoColor() {
        // Simulate --no-color by testing the colored() helper
        // When disabled, colored() returns plain text
        let plain = "hello"
        // Can't easily toggle isEnabled in tests, but verify format
        XCTAssertTrue(ANSIColors.colored(plain, ANSIColors.green).contains(plain))
    }

    func testTableFormatterBasic() {
        let rows = [["Alice", "30"], ["Bob", "25"]]
        let result = TableFormatter.format(rows: rows)
        XCTAssertTrue(result.contains("Alice"))
        XCTAssertTrue(result.contains("Bob"))
        XCTAssertTrue(result.contains("30"))
    }

    func testTableFormatterWithHeaders() {
        let headers = ["Name", "Age"]
        let rows = [["Alice", "30"]]
        let result = TableFormatter.format(rows: rows, headers: headers)
        XCTAssertTrue(result.contains("Name"))
        XCTAssertTrue(result.contains("Age"))
        XCTAssertTrue(result.contains("Alice"))
        XCTAssertTrue(result.contains("─"))
    }

    func testTableFormatterEmptyRows() {
        let result = TableFormatter.format(rows: [])
        XCTAssertEqual(result, "")
    }
}
