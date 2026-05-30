import Foundation

final class LocalLogger {
    static let shared = LocalLogger()

    private let isoFormatter = ISO8601DateFormatter()

    private init() {}

    func info(_ message: String) {
        log(level: "info", message: message)
    }

    func error(_ message: String) {
        log(level: "error", message: message)
    }

    private func log(level: String, message: String) {
        let timestamp = isoFormatter.string(from: Date())
        print("\(timestamp) level=\(level) \(message)")
    }
}
