import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    static let shared = AudioRecorder()

    @Published private(set) var state: AudioSessionState = .idle
    @Published private(set) var lastRecordingURL: URL?
    @Published private(set) var lastRecordingDurationMs: Int = 0
    @Published private(set) var lastRecordingSizeBytes: Int = 0
    @Published private(set) var lastRecordingPeakLevel: Double = 0
    @Published private(set) var statusMessage: String = "No recording yet."
    @Published private(set) var waveformLevels: [Double] = Array(repeating: 0.08, count: 18)

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingStartedAt: Date?
    private var meteringTask: Task<Void, Never>?
    private var currentRecordingPeakLevel: Double = 0

    private override init() {
        super.init()
    }

    func startRecording() async throws {
        guard state != .recording else { return }

        let permissionGranted: Bool
        switch PermissionsManager.shared.microphonePermissionStatus {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            permissionGranted = await PermissionsManager.shared.requestMicrophonePermission()
        default:
            permissionGranted = false
        }

        guard permissionGranted else {
            state = .error
            statusMessage = PermissionsManager.shared.microphonePermissionDescription()
            throw AudioRecorderError.microphonePermissionDenied
        }

        let url = makeTempRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()

            guard recorder.record() else {
                throw AudioRecorderError.couldNotStartRecording
            }

            self.recorder = recorder
            recordingStartedAt = Date()
            lastRecordingURL = url
            lastRecordingDurationMs = 0
            lastRecordingSizeBytes = 0
            lastRecordingPeakLevel = 0
            currentRecordingPeakLevel = 0
            state = .recording
            statusMessage = "Recording…"
            startMetering()
        } catch {
            state = .error
            statusMessage = "Failed to start recording: \(error.localizedDescription)"
            throw error
        }
    }

    func stopRecording() throws -> URL? {
        guard let recorder, state == .recording else { return lastRecordingURL }

        state = .stopping
        stopMetering()
        recorder.stop()
        self.recorder = nil

        let durationMs = Int(Date().timeIntervalSince(recordingStartedAt ?? Date()) * 1000)
        recordingStartedAt = nil
        lastRecordingDurationMs = durationMs

        if let url = lastRecordingURL {
            lastRecordingSizeBytes = fileSize(url: url)
            lastRecordingPeakLevel = currentRecordingPeakLevel
            statusMessage = "Recorded \(durationMs) ms, \(lastRecordingSizeBytes) bytes, peak \(String(format: "%.2f", lastRecordingPeakLevel))."
        } else {
            statusMessage = "Recording stopped, but file URL is missing."
        }

        state = .idle
        return lastRecordingURL
    }

    func playLastRecording() throws {
        guard let url = lastRecordingURL else {
            throw AudioRecorderError.noRecording
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioRecorderError.recordingFileMissing
        }

        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.play()
        state = .playing
        statusMessage = "Playing last recording…"

        let playbackDuration = player?.duration ?? 0
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(max(playbackDuration, 0.1) * 1_000_000_000))
            if state == .playing {
                state = .idle
                statusMessage = "Playback finished."
            }
        }
    }

    func deleteLastRecordingIfNeeded(keepForDebugging: Bool) {
        guard !keepForDebugging, let url = lastRecordingURL else { return }
        try? FileManager.default.removeItem(at: url)
        lastRecordingURL = nil
        lastRecordingDurationMs = 0
        lastRecordingSizeBytes = 0
        lastRecordingPeakLevel = 0
        currentRecordingPeakLevel = 0
        statusMessage = "Last recording deleted."
    }

    private func startMetering() {
        meteringTask?.cancel()
        waveformLevels = Array(repeating: 0.08, count: 18)
        meteringTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.sampleMeter()
                }
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
        }
    }

    private func stopMetering() {
        meteringTask?.cancel()
        meteringTask = nil
        waveformLevels = Array(repeating: 0.08, count: 18)
    }

    private func sampleMeter() {
        guard let recorder, state == .recording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = normalizedPower(power)
        let previous = waveformLevels.last ?? 0.08
        let smoothed = previous * 0.45 + normalized * 0.55
        currentRecordingPeakLevel = max(currentRecordingPeakLevel, smoothed)
        waveformLevels.append(smoothed)
        if waveformLevels.count > 18 {
            waveformLevels.removeFirst(waveformLevels.count - 18)
        }
    }

    private func normalizedPower(_ decibels: Float) -> Double {
        if decibels <= -45 { return 0.06 }
        if decibels >= -7 { return 1.0 }
        let minDb: Float = -45
        let maxDb: Float = -7
        let level = (decibels - minDb) / (maxDb - minDb)
        let noiseGateAdjusted = max(0, level - 0.10) / 0.90
        return Double(max(0.06, min(1.0, pow(noiseGateAdjusted, 1.08))))
    }

    private func makeTempRecordingURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("pastevox-recording-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
    }

    private func fileSize(url: URL) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int ?? 0
    }
}

enum AudioRecorderError: LocalizedError {
    case microphonePermissionDenied
    case couldNotStartRecording
    case noRecording
    case recordingFileMissing

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Microphone permission denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .couldNotStartRecording:
            "Could not start microphone recording."
        case .noRecording:
            "No recording available."
        case .recordingFileMissing:
            "Last recording file is missing."
        }
    }
}
