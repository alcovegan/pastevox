import AppKit
import AVFoundation

@MainActor
final class FeedbackService {
    static let shared = FeedbackService()

    private var sounds: [FeedbackSound: NSSound] = [:]
    private var lastHapticAt = Date.distantPast

    private init() {}

    func recordingStarted() {
        // Single, debounced haptic only. No start sound.
        haptic(.generic)
    }

    func recordingEnded() {
        haptic(.alignment)
        sound(.release)
    }

    func success() {
        haptic(.levelChange)
        sound(.success)
    }

    func error() {
        haptic(.generic)
        sound(.error)
    }

    private func haptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        guard AppSettings.shared.hapticFeedbackEnabled else { return }
        let now = Date()
        guard now.timeIntervalSince(lastHapticAt) > 0.18 else { return }
        lastHapticAt = now
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    private func sound(_ feedbackSound: FeedbackSound) {
        guard AppSettings.shared.soundFeedbackEnabled else { return }
        let sound = sounds[feedbackSound] ?? makeSound(feedbackSound)
        sounds[feedbackSound] = sound
        sound.stop()
        sound.currentTime = 0
        sound.volume = feedbackSound.volume
        sound.play()
    }

    private func makeSound(_ feedbackSound: FeedbackSound) -> NSSound {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pastevox-feedback-\(feedbackSound.rawValue).wav")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? makeWAVData(for: feedbackSound).write(to: url)
        }
        return NSSound(contentsOf: url, byReference: false) ?? NSSound()
    }

    private func makeWAVData(for feedbackSound: FeedbackSound) -> Data {
        let sampleRate = 44_100
        let samples = feedbackSound.samples(sampleRate: sampleRate)
        var pcm = Data()
        pcm.reserveCapacity(samples.count * 2)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Double(Int16.max))
            pcm.append(UInt8(truncatingIfNeeded: intSample & 0xff))
            pcm.append(UInt8(truncatingIfNeeded: (intSample >> 8) & 0xff))
        }

        var data = Data()
        data.appendString("RIFF")
        data.appendUInt32LE(UInt32(36 + pcm.count))
        data.appendString("WAVE")
        data.appendString("fmt ")
        data.appendUInt32LE(16)
        data.appendUInt16LE(1)
        data.appendUInt16LE(1)
        data.appendUInt32LE(UInt32(sampleRate))
        data.appendUInt32LE(UInt32(sampleRate * 2))
        data.appendUInt16LE(2)
        data.appendUInt16LE(16)
        data.appendString("data")
        data.appendUInt32LE(UInt32(pcm.count))
        data.append(pcm)
        return data
    }
}

private enum FeedbackSound: String {
    case release
    case success
    case error

    var volume: Float {
        switch self {
        case .release: 0.12
        case .success: 0.16
        case .error: 0.14
        }
    }

    func samples(sampleRate: Int) -> [Double] {
        switch self {
        case .release:
            tone(frequency: 520, duration: 0.045, sampleRate: sampleRate, gain: 0.18)
        case .success:
            tone(frequency: 660, duration: 0.040, sampleRate: sampleRate, gain: 0.16)
            + tone(frequency: 880, duration: 0.055, sampleRate: sampleRate, gain: 0.14)
        case .error:
            tone(frequency: 220, duration: 0.075, sampleRate: sampleRate, gain: 0.16)
        }
    }

    private func tone(frequency: Double, duration: Double, sampleRate: Int, gain: Double) -> [Double] {
        let count = max(1, Int(duration * Double(sampleRate)))
        return (0..<count).map { index in
            let t = Double(index) / Double(sampleRate)
            let progress = Double(index) / Double(count)
            let attack = min(1.0, progress / 0.16)
            let release = min(1.0, (1.0 - progress) / 0.28)
            let envelope = max(0.0, min(attack, release))
            return sin(2.0 * .pi * frequency * t) * envelope * gain
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}
