// StartWatch — FileWatcher: FSEvents-based file monitoring with 200ms debounce
import Foundation
import Dispatch

public class FileWatcher {
    private let configDirectoryURL: URL
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceQueue = DispatchQueue(label: "com.startwatch.filewatcher.debounce")
    private let onChange: () -> Void

    public init(configDirectoryURL: URL, onChange: @escaping () -> Void) {
        self.configDirectoryURL = configDirectoryURL
        self.onChange = onChange
    }

    public func start() throws {
        guard fileDescriptor == -1 else { return }

        let path = configDirectoryURL.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            throw FileWatcherError.cannotOpenDirectory(path: path)
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: DispatchQueue.global()
        )

        source?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }

        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd != -1 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source?.resume()
    }

    private func handleFileSystemEvent() {
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        debounceQueue.asyncAfter(deadline: .now() + 0.2, execute: debounceWorkItem!)
    }

    public func stop() {
        debounceWorkItem?.cancel()
        source?.cancel()
        source = nil

        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    deinit {
        stop()
    }
}

public enum FileWatcherError: Error {
    case cannotOpenDirectory(path: String)
}
