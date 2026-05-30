import Foundation

struct DictationMetrics: Identifiable {
    let id = UUID()
    let startedAt = Date()
    var hotkeyDownToRecordingStartedMs: Int?
    var hotkeyUpToAudioFinalizedMs: Int?
    var recordingDurationMs: Int?
    var audioFileSizeBytes: Int?
    var transcriptionDurationMs: Int?
    var postprocessDurationMs: Int?
    var pasteDurationMs: Int?
    var totalReleaseToPasteMs: Int?
    var model: String?
    var promptMode: PromptMode?
    var transcriptionMode: TranscriptionMode?
    var success: Bool = false
    var errorType: String?

    var summary: String {
        let total = totalReleaseToPasteMs.map { "\($0)ms" } ?? "n/a"
        let mode = promptMode?.title ?? "n/a"
        let transcription = transcriptionMode?.title ?? "n/a"
        let status = success ? "success" : "failure"
        return "\(status) total=\(total) prompt=\(mode) transcription=\(transcription)"
    }
}

@MainActor
final class MetricsStore: ObservableObject {
    static let shared = MetricsStore()

    @Published private(set) var sessions: [DictationMetrics] = []

    private let maxSessions = 25

    private init() {}

    func add(_ metrics: DictationMetrics) {
        sessions.insert(metrics, at: 0)
        if sessions.count > maxSessions {
            sessions.removeLast(sessions.count - maxSessions)
        }
    }

    func clear() {
        sessions.removeAll()
    }

    func totalReleaseToPasteStats() -> (min: Int, avg: Int, max: Int)? {
        let values = successfulSessions.compactMap(\.totalReleaseToPasteMs)
        guard !values.isEmpty else { return nil }
        return (values.min() ?? 0, values.reduce(0, +) / values.count, values.max() ?? 0)
    }

    func metricsReport() -> String {
        var lines: [String] = []
        lines.append("VoiceDock metrics report")
        if let stats = totalReleaseToPasteStats() {
            lines.append("successful total_release_to_paste min/avg/max: \(stats.min)/\(stats.avg)/\(stats.max) ms")
        } else {
            lines.append("successful total_release_to_paste: n/a")
        }

        appendModeStats(title: "Total by mode", stats: totalStatsByTranscriptionMode(), lines: &lines)
        appendModeStats(title: "STT by mode", stats: sttStatsByTranscriptionMode(), lines: &lines)

        lines.append("Sessions:")
        for metric in sessions {
            lines.append("- \(metric.summary); model=\(metric.model ?? "n/a"); record=\(metric.recordingDurationMs.map(String.init) ?? "n/a")ms; audio=\(metric.audioFileSizeBytes.map(String.init) ?? "n/a")B; stt=\(metric.transcriptionDurationMs.map(String.init) ?? "n/a")ms; post=\(metric.postprocessDurationMs.map(String.init) ?? "n/a")ms; paste=\(metric.pasteDurationMs.map(String.init) ?? "n/a")ms; error=\(metric.errorType ?? "none")")
        }
        return lines.joined(separator: "\n")
    }

    func totalStatsByTranscriptionMode() -> [(mode: TranscriptionMode, count: Int, min: Int, avg: Int, max: Int)] {
        statsByTranscriptionMode(values: { $0.totalReleaseToPasteMs })
    }

    func sttStatsByTranscriptionMode() -> [(mode: TranscriptionMode, count: Int, min: Int, avg: Int, max: Int)] {
        statsByTranscriptionMode(values: { $0.transcriptionDurationMs })
    }

    private func statsByTranscriptionMode(values value: (DictationMetrics) -> Int?) -> [(mode: TranscriptionMode, count: Int, min: Int, avg: Int, max: Int)] {
        TranscriptionMode.allCases.compactMap { mode in
            let values = successfulSessions
                .filter { $0.transcriptionMode == mode }
                .compactMap(value)
            guard !values.isEmpty else { return nil }
            return (mode, values.count, values.min() ?? 0, values.reduce(0, +) / values.count, values.max() ?? 0)
        }
    }

    private func appendModeStats(
        title: String,
        stats: [(mode: TranscriptionMode, count: Int, min: Int, avg: Int, max: Int)],
        lines: inout [String]
    ) {
        if stats.isEmpty {
            lines.append("\(title): n/a")
        } else {
            lines.append("\(title):")
            for stat in stats {
                lines.append("- \(stat.mode.title): n=\(stat.count), min/avg/max \(stat.min)/\(stat.avg)/\(stat.max) ms")
            }
        }
    }

    private var successfulSessions: [DictationMetrics] {
        sessions.filter(\.success)
    }
}
