// StartWatch — FileWatcherTests: проверка детекции изменений файла
import XCTest
@testable import StartWatch

final class FileWatcherTests: XCTestCase {

    var tempDir: String!
    var testConfigPath: String!

    override func setUp() {
        super.setUp()
        tempDir = NSTemporaryDirectory() + "/startwatch-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        testConfigPath = tempDir + "/test-config.json"
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        super.tearDown()
    }

    func testFileWatcherDetectsChange() throws {
        // Create initial config file
        let initialContent = """
        {
            "services": [{"name": "Service1", "check": {"type": "port", "value": "8000"}}]
        }
        """.data(using: .utf8)!
        FileManager.default.createFile(atPath: testConfigPath, contents: initialContent)

        // Setup expectation for callback
        let changeDetectedExpectation = XCTestExpectation(description: "File change detected")

        // Start FileWatcher
        let watcher = FileWatcher(filePath: testConfigPath)
        watcher.start {
            changeDetectedExpectation.fulfill()
        }

        // Wait slightly to ensure FileWatcher has initialized
        Thread.sleep(forTimeInterval: 0.1)

        // Modify file (write with small delay to ensure mtime changes)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            let newContent = """
            {
                "services": [
                    {"name": "Service1", "check": {"type": "port", "value": "8000"}},
                    {"name": "Service2", "check": {"type": "port", "value": "8001"}}
                ]
            }
            """.data(using: .utf8)!
            try? newContent.write(toFile: self.testConfigPath, options: .atomic)
        }

        // Wait for callback (max 3 seconds)
        wait(for: [changeDetectedExpectation], timeout: 3.0)

        watcher.stop()
    }

    func testFileWatcherIgnoresInitialState() throws {
        // Create file
        let content = """
        {
            "services": [{"name": "Service1", "check": {"type": "port", "value": "8000"}}]
        }
        """.data(using: .utf8)!
        FileManager.default.createFile(atPath: testConfigPath, contents: content)

        // Setup expectation that should NOT be fulfilled for initial state
        let changeDetectedExpectation = XCTestExpectation(description: "File change detected")
        changeDetectedExpectation.isInverted = true  // Expect this NOT to be called

        // Start FileWatcher
        let watcher = FileWatcher(filePath: testConfigPath)
        watcher.start {
            changeDetectedExpectation.fulfill()
        }

        // Wait 1 second - should not detect change on initial state
        wait(for: [changeDetectedExpectation], timeout: 1.0)

        watcher.stop()
    }

    func testFileWatcherMultipleChanges() throws {
        // Create initial config file
        let initialContent = """
        {
            "services": [{"name": "Service1", "check": {"type": "port", "value": "8000"}}]
        }
        """.data(using: .utf8)!
        FileManager.default.createFile(atPath: testConfigPath, contents: initialContent)

        // Setup expectations for two changes
        let change1Expectation = XCTestExpectation(description: "First change detected")
        let change2Expectation = XCTestExpectation(description: "Second change detected")
        var changeCount = 0

        // Start FileWatcher with counter
        let watcher = FileWatcher(filePath: testConfigPath)
        watcher.start {
            changeCount += 1
            if changeCount == 1 {
                change1Expectation.fulfill()
            } else if changeCount == 2 {
                change2Expectation.fulfill()
            }
        }

        // Wait for initialization
        Thread.sleep(forTimeInterval: 0.1)

        // First modification
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            let content1 = """
            {
                "services": [
                    {"name": "Service1", "check": {"type": "port", "value": "8000"}},
                    {"name": "Service2", "check": {"type": "port", "value": "8001"}}
                ]
            }
            """.data(using: .utf8)!
            try? content1.write(toFile: self.testConfigPath, options: .atomic)
        }

        // Second modification (after first is detected)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            let content2 = """
            {
                "services": [
                    {"name": "Service1", "check": {"type": "port", "value": "8000"}},
                    {"name": "Service2", "check": {"type": "port", "value": "8001"}},
                    {"name": "Service3", "check": {"type": "port", "value": "8002"}}
                ]
            }
            """.data(using: .utf8)!
            try? content2.write(toFile: self.testConfigPath, options: .atomic)
        }

        // Wait for both changes
        wait(for: [change1Expectation, change2Expectation], timeout: 4.0)

        watcher.stop()
    }
}
