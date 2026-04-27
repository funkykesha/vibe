// StartWatch — ConfigTests: тесты парсинга и валидации конфига
import XCTest
@testable import StartWatch

final class ConfigTests: XCTestCase {

    func testParseValidConfig() throws {
        let json = """
        {
            "terminal": "warp",
            "checkIntervalMinutes": 60,
            "services": [
                {
                    "name": "Redis",
                    "check": { "type": "port", "value": "6379" }
                }
            ]
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(AppConfig.self, from: json)
        XCTAssertEqual(config.terminal, "warp")
        XCTAssertEqual(config.services.count, 1)
        XCTAssertEqual(config.services[0].name, "Redis")
        XCTAssertEqual(config.services[0].check.type, .port)
        XCTAssertEqual(config.services[0].check.value, "6379")
    }

    func testParseBrokenJSON() {
        let broken = "{ not valid json }".data(using: .utf8)!
        let config = try? JSONDecoder().decode(AppConfig.self, from: broken)
        XCTAssertNil(config)
    }

    func testValidateEmptyServices() {
        let json = """
        { "services": [] }
        """.data(using: .utf8)!
        let config = try? JSONDecoder().decode(AppConfig.self, from: json)
        XCTAssertNotNil(config)
        let errors = ConfigManager.validate(config!)
        XCTAssertTrue(errors.contains("No services configured"))
    }

    func testValidateValidConfig() {
        let json = """
        {
            "services": [
                { "name": "Test", "check": { "type": "port", "value": "8080" } }
            ]
        }
        """.data(using: .utf8)!
        let config = try! JSONDecoder().decode(AppConfig.self, from: json)
        let errors = ConfigManager.validate(config)
        XCTAssertTrue(errors.isEmpty)
    }

    func testAllCheckTypes() throws {
        for type_ in ["process", "port", "http", "command"] {
            let json = """
            {
                "services": [
                    { "name": "Test", "check": { "type": "\(type_)", "value": "test" } }
                ]
            }
            """.data(using: .utf8)!
            let config = try JSONDecoder().decode(AppConfig.self, from: json)
            XCTAssertEqual(config.services[0].check.type.rawValue, type_)
        }
    }

    func testOptionalFields() throws {
        let json = """
        {
            "services": [
                { "name": "Minimal", "check": { "type": "port", "value": "3000" } }
            ]
        }
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(AppConfig.self, from: json)
        XCTAssertNil(config.terminal)
        XCTAssertNil(config.checkIntervalMinutes)
        XCTAssertNil(config.services[0].start)
        XCTAssertNil(config.services[0].tags)
    }
}
