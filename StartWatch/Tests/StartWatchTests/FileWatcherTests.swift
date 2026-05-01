// StartWatch — FileWatcherTests: FSEvents-based file monitoring tests
import XCTest
@testable import StartWatch

final class FileWatcherTests: XCTestCase {

    var tempDir: URL!
    var testConfigPath: URL!

    override func setUp() {
        super.setUp()
        let tempPath = NSTemporaryDirectory() + "/startwatch-test-\(UUID().uuidString)"
        tempDir = URL(fileURLWithPath: tempPath)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        testConfigPath = tempDir.appendingPathComponent("test-config.json")
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testFileWatcherDetectsFileChange() throws {
        // Create initial config file
        let initialContent = """
        {
            "services": [{"name": "Service1", "check": {"type": "port", "value": "8000"}}]
        }
        """.data(using: .utf8)!
        try initialContent.write(to: testConfigPath)

        // Setup expectation for callback
        let changeDetectedExpectation = XCTestExpectation(description: "File change detected")

        // Start FileWatcher monitoring the directory
        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        // Wait slightly to ensure FileWatcher has initialized
        Thread.sleep(forTimeInterval: 0.1)

        // Modify file (write with delay to ensure mtime changes)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            let newContent = """
            {
                "services": [
                    {"name": "Service1", "check": {"type": "port", "value": "8000"}},
                    {"name": "Service2", "check": {"type": "port", "value": "8001"}}
                ]
            }
            """.data(using: .utf8)!
            try? newContent.write(to: self.testConfigPath, options: .atomic)
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
        try content.write(to: testConfigPath)

        // Setup expectation that should NOT be fulfilled for initial state
        let changeDetectedExpectation = XCTestExpectation(description: "File change detected")
        changeDetectedExpectation.isInverted = true  // Expect this NOT to be called

        // Start FileWatcher
        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

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
        try initialContent.write(to: testConfigPath)

        // Setup expectations for two changes
        let change1Expectation = XCTestExpectation(description: "First change detected")
        let change2Expectation = XCTestExpectation(description: "Second change detected")
        var changeCount = 0

        // Start FileWatcher with counter
        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeCount += 1
            if changeCount == 1 {
                change1Expectation.fulfill()
            } else if changeCount == 2 {
                change2Expectation.fulfill()
            }
        }
        try watcher.start()

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
            try? content1.write(to: self.testConfigPath, options: .atomic)
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
            try? content2.write(to: self.testConfigPath, options: .atomic)
        }

        // Wait for both changes
        wait(for: [change1Expectation, change2Expectation], timeout: 4.0)

        watcher.stop()
    }

    // MARK: - Debounce Tests

    func testFileWatcherDebounce200ms() throws {
        // Create initial config file
        let initialContent = """
        {"services": []}
        """.data(using: .utf8)!
        try initialContent.write(to: testConfigPath)

        // Setup single expectation - rapid changes should trigger only once
        let changeDetectedExpectation = XCTestExpectation(description: "Change detected (debounced)")
        changeDetectedExpectation.assertForOverFulfill = false

        var callCount = 0

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            callCount += 1
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Trigger multiple rapid changes within 200ms
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            try? "{\"services\": [1]}".data(using: .utf8)?.write(to: self.testConfigPath, options: .atomic)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            try? "{\"services\": [2]}".data(using: .utf8)?.write(to: self.testConfigPath, options: .atomic)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
            try? "{\"services\": [3]}".data(using: .utf8)?.write(to: self.testConfigPath, options: .atomic)
        }

        // Wait for debounced callback (should fire once after 200ms from last change)
        wait(for: [changeDetectedExpectation], timeout: 2.0)

        // Verify only one callback despite multiple changes
        XCTAssertEqual(callCount, 1, "Debounce should result in exactly one callback")

        watcher.stop()
    }

    // MARK: - Directory Monitoring Tests

    func testFileWatcherMonitorsDirectory() throws {
        // Create multiple config files in the directory
        let config1Path = tempDir.appendingPathComponent("config1.json")
        let config2Path = tempDir.appendingPathComponent("config2.json")

        try "{}".data(using: .utf8)?.write(to: config1Path)
        try "{}".data(using: .utf8)?.write(to: config2Path)

        // Expectation for changes to either file
        let changeDetectedExpectation = XCTestExpectation(description: "Directory change detected")
        changeDetectedExpectation.assertForOverFulfill = false

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Modify one file in the directory
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? "{\"test\": true}".data(using: .utf8)?.write(to: config1Path, options: .atomic)
        }

        wait(for: [changeDetectedExpectation], timeout: 2.0)

        watcher.stop()
    }

    func testFileWatcherDetectsNewFile() throws {
        // Directory starts empty (no config files)
        let newConfigPath = tempDir.appendingPathComponent("new-config.json")

        let changeDetectedExpectation = XCTestExpectation(description: "New file detected")

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Create a new file in the directory
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? "{\"test\": true}".data(using: .utf8)?.write(to: newConfigPath, options: .atomic)
        }

        wait(for: [changeDetectedExpectation], timeout: 2.0)

        watcher.stop()
    }

    func testFileWatcherDetectsFileDeletion() throws {
        // Create config file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        let changeDetectedExpectation = XCTestExpectation(description: "File deletion detected")

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Delete the file
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? FileManager.default.removeItem(at: self.testConfigPath)
        }

        wait(for: [changeDetectedExpectation], timeout: 2.0)

        watcher.stop()
    }

    // MARK: - Error Handling Tests

    func testFileWatcherInvalidDirectory() throws {
        let invalidDir = URL(fileURLWithPath: "/nonexistent/path/that/does/not/exist")

        let watcher = FileWatcher(configDirectoryURL: invalidDir) {
            // This should never be called
            XCTFail("Callback should not be called for invalid directory")
        }

        do {
            try watcher.start()
            XCTFail("Expected FileWatcherError for invalid directory")
        } catch let error as FileWatcherError {
            // Expected error
            switch error {
            case .cannotOpenDirectory:
                break  // Expected
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileWatcherStartTwiceIsIdempotent() throws {
        // Create file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        let watcher = FileWatcher(configDirectoryURL: tempDir) {}
        try watcher.start()

        // Calling start again should be safe (idempotent)
        try watcher.start()

        watcher.stop()

        // Should be able to start again after stop
        try watcher.start()
        watcher.stop()
    }

    // MARK: - Stop Functionality Tests

    func testFileWatcherStopPreventsCallbacks() throws {
        // Create file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        let callbackExpectation = XCTestExpectation(description: "Callback after stop")
        callbackExpectation.isInverted = true

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            callbackExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Stop the watcher
        watcher.stop()

        // Modify file after stopping
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? "{\"test\": true}".data(using: .utf8)?.write(to: self.testConfigPath, options: .atomic)
        }

        // Wait - should NOT receive callback after stop
        wait(for: [callbackExpectation], timeout: 1.5)
    }

    func testFileWatcherStopMultipleTimesIsSafe() throws {
        // Create file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        let watcher = FileWatcher(configDirectoryURL: tempDir) {}
        try watcher.start()

        // Stop multiple times should be safe
        watcher.stop()
        watcher.stop()
        watcher.stop()

        // Should not crash or throw
        XCTAssertTrue(true, "Multiple stop calls should be safe")
    }

    // MARK: - Deinit Cleanup Tests

    func testFileWatcherDeinitCleansUp() throws {
        // Create file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        var watcher: FileWatcher? = FileWatcher(configDirectoryURL: tempDir) {
            XCTFail("Callback should not be called after deinit")
        }
        try watcher?.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Deallocate the watcher
        watcher = nil

        // Modify file - should not crash and callback should not fire
        // (We can't easily verify the callback doesn't fire without a delay,
        // but the test verifies deinit doesn't crash)
        Thread.sleep(forTimeInterval: 0.5)
        try? "{\"test\": true}".data(using: .utf8)?.write(to: testConfigPath, options: .atomic)

        // Give some time to ensure no crash
        Thread.sleep(forTimeInterval: 0.5)
    }

    func testFileWatcherMultipleInstances() throws {
        // Create separate temp directories
        let tempDir2Path = NSTemporaryDirectory() + "/startwatch-test2-\(UUID().uuidString)"
        let tempDir2 = URL(fileURLWithPath: tempDir2Path)
        try FileManager.default.createDirectory(at: tempDir2, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir2)
        }

        let config1Path = tempDir.appendingPathComponent("config1.json")
        let config2Path = tempDir2.appendingPathComponent("config2.json")

        try "{}".data(using: .utf8)?.write(to: config1Path)
        try "{}".data(using: .utf8)?.write(to: config2Path)

        let expectation1 = XCTestExpectation(description: "Watcher 1 change")
        let expectation2 = XCTestExpectation(description: "Watcher 2 change")

        let watcher1 = FileWatcher(configDirectoryURL: tempDir) {
            expectation1.fulfill()
        }
        let watcher2 = FileWatcher(configDirectoryURL: tempDir2) {
            expectation2.fulfill()
        }

        try watcher1.start()
        try watcher2.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Modify file in first directory
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? "{\"test\": 1}".data(using: .utf8)?.write(to: config1Path, options: .atomic)
        }

        // Modify file in second directory
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.7) {
            try? "{\"test\": 2}".data(using: .utf8)?.write(to: config2Path, options: .atomic)
        }

        wait(for: [expectation1, expectation2], timeout: 3.0)

        watcher1.stop()
        watcher2.stop()
    }

    // MARK: - Rename Detection Tests

    func testFileWatcherDetectsFileRename() throws {
        // Create initial file
        try "{}".data(using: .utf8)?.write(to: testConfigPath)

        let changeDetectedExpectation = XCTestExpectation(description: "File rename detected")

        let watcher = FileWatcher(configDirectoryURL: tempDir) {
            changeDetectedExpectation.fulfill()
        }
        try watcher.start()

        Thread.sleep(forTimeInterval: 0.1)

        // Rename the file
        let renamedPath = tempDir.appendingPathComponent("renamed-config.json")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            try? FileManager.default.moveItem(at: self.testConfigPath, to: renamedPath)
        }

        wait(for: [changeDetectedExpectation], timeout: 2.0)

        watcher.stop()
    }
}
