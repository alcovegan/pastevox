import Foundation

final class LocalLogger {
    static let shared = LocalLogger()

    private let isoFormatter = ISO8601DateFormatter()
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.voicedock.local-logger")

    private init() {
        let logsDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/VoiceDock", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        logFileURL = logsDirectory.appendingPathComponent("voicedock.log")
    }

    func info(_ message: String) {
        log(level: "info", message: message)
    }

    func error(_ message: String) {
        log(level: "error", message: message)
    }

    func logFilePath() -> String {
        logFileURL.path
    }

    private func log(level: String, message: String) {
        let timestamp = isoFormatter.string(from: Date())
        let line = "\(timestamp) level=\(level) \(message)"
        print(line)
        queue.async { [logFileURL] in
            guard let data = (line + "\n").data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}
