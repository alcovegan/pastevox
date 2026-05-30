@preconcurrency import AVFoundation
import Foundation

@MainActor
final class OpenAIRealtimeTranscriber: ObservableObject {
    @Published private(set) var partialTranscript = ""
    @Published private(set) var status = "Realtime idle."

    private let apiKeyProvider: () throws -> String?
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?
    private var finalContinuation: CheckedContinuation<TranscriptionResult, Error>?
    private var context: TranscriptionContext?
    private var startedAt: Date?
    private var finalTranscript = ""
    private var loggedAppendFailure = false
    private var audioBytesSent = 0

    init(
        apiKeyProvider: @escaping () throws -> String? = { try KeychainStore.shared.loadOpenAIAPIKey() },
        fileTranscriber: OpenAIFileTranscriber = OpenAIFileTranscriber(),
        session: URLSession = .shared
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    func transcribeCompletedRecording(audioURL: URL, context: TranscriptionContext) async throws -> TranscriptionResult {
        let startedAt = Date()
        LocalLogger.shared.info("transcription_mode=streaming_completed_recording status=started transport=urlsession_bytes")

        guard let apiKey = try apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        let audioData: Data
        do { audioData = try Data(contentsOf: audioURL) }
        catch { throw TranscriptionError.unsupportedAudio("Could not read selected audio file.") }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(boundary: boundary, model: context.model, audioURL: audioURL, audioData: audioData)

        let (bytes, response) = try await session.bytes(for: request)
        try validate(response: response)

        var responseData = Data()
        for try await byte in bytes { responseData.append(byte) }

        guard let text = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw TranscriptionError.emptyTranscript
        }

        let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        LocalLogger.shared.info("transcription_mode=streaming_completed_recording status=success duration_ms=\(durationMs)")
        return TranscriptionResult(text: text, durationMs: durationMs, model: context.model, isPartial: false)
    }

    func startRealtimeMicrophone(context: TranscriptionContext) async throws {
        try stopRealtimeMicrophoneIfNeeded()

        guard let apiKey = try apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        self.context = context
        partialTranscript = ""
        finalTranscript = ""
        loggedAppendFailure = false
        audioBytesSent = 0
        startedAt = Date()
        status = "Connecting realtime websocket…"

        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!)
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let task = session.webSocketTask(with: request)
        webSocketTask = task
        task.resume()

        receiveLoop()
        try await sendJSON([
            "type": "session.update",
            "session": [
                "type": "transcription",
                "audio": [
                    "input": [
                        "format": [
                            "type": "audio/pcm",
                            "rate": 24000
                        ],
                        "transcription": [
                            "model": context.model,
                            "language": "ru",
                            "prompt": "Русская речь. Сохраняй русские имена: Михаил Палыч. Сохраняй технические термины."
                        ],
                        "turn_detection": nil
                    ]
                ]
            ]
        ])

        try startAudioEngine()
        status = "Realtime microphone streaming…"
        LocalLogger.shared.info("transcription_mode=realtime_microphone_streaming status=started")
    }

    func finishRealtimeMicrophone() async throws -> TranscriptionResult {
        guard webSocketTask != nil else { throw RealtimeTranscriptionError.sessionNotStarted }
        status = "Finalizing realtime transcript…"
        stopAudioEngine()
        if audioBytesSent >= 4_800 {
            try await sendJSON(["type": "input_audio_buffer.commit"])
        } else {
            throw RealtimeTranscriptionError.notEnoughAudioSent
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                finalContinuation = continuation
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 8_000_000_000)
                    if let finalContinuation = self.finalContinuation {
                        self.finalContinuation = nil
                        if !self.finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalContinuation.resume(returning: self.makeRealtimeResult(text: self.finalTranscript))
                        } else {
                            finalContinuation.resume(throwing: RealtimeTranscriptionError.finalTranscriptTimeout)
                        }
                        self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
                        self.webSocketTask = nil
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in try? self.stopRealtimeMicrophoneIfNeeded() }
        }
    }

    func transcribeRealtimeMicrophone(context: TranscriptionContext) async throws -> TranscriptionResult {
        throw RealtimeTranscriptionError.sessionNotStarted
    }

    private func startAudioEngine() throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let pcm = Self.pcm16Data(from: buffer)
            guard !pcm.isEmpty else { return }
            Task { @MainActor in
                do {
                    try await self.sendJSON([
                        "type": "input_audio_buffer.append",
                        "audio": pcm.base64EncodedString()
                    ])
                    self.audioBytesSent += pcm.count
                } catch {
                    if !self.loggedAppendFailure {
                        self.loggedAppendFailure = true
                        LocalLogger.shared.error("realtime_microphone_streaming append_failed error=\(error.localizedDescription)")
                    }
                }
            }
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
    }

    private func stopAudioEngine() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    private func stopRealtimeMicrophoneIfNeeded() throws {
        stopAudioEngine()
        finalContinuation = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        status = "Realtime idle."
    }

    private nonisolated static func pcm16Data(from buffer: AVAudioPCMBuffer) -> Data {
        let targetSampleRate: Double = 24_000
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else { return Data() }

        let sourceFormat = buffer.format
        let convertedBuffer: AVAudioPCMBuffer

        if abs(sourceFormat.sampleRate - targetSampleRate) < 1, sourceFormat.channelCount == 1 {
            convertedBuffer = buffer
        } else {
            guard
                let converter = AVAudioConverter(from: sourceFormat, to: targetFormat),
                let outputBuffer = AVAudioPCMBuffer(
                    pcmFormat: targetFormat,
                    frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * targetSampleRate / sourceFormat.sampleRate) + 16
                )
            else { return Data() }

            var didProvideInput = false
            var conversionError: NSError?
            converter.convert(to: outputBuffer, error: &conversionError) { _, status in
                if didProvideInput {
                    status.pointee = .noDataNow
                    return nil
                }
                didProvideInput = true
                status.pointee = .haveData
                return buffer
            }

            guard conversionError == nil else { return Data() }
            convertedBuffer = outputBuffer
        }

        guard let channel = convertedBuffer.floatChannelData?[0] else { return Data() }
        let frames = Int(convertedBuffer.frameLength)
        var data = Data(capacity: frames * 2)
        for index in 0..<frames {
            let sample = max(-1.0, min(1.0, channel[index]))
            var intSample = Int16(sample * Float(Int16.max)).littleEndian
            withUnsafeBytes(of: &intSample) { data.append(contentsOf: $0) }
        }
        return data
    }

    private func receiveLoop() {
        guard let webSocketTask else { return }
        webSocketTask.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    if self.webSocketTask != nil { self.receiveLoop() }
                case .failure(let error):
                    self.status = "Realtime receive error: \(error.localizedDescription)"
                    LocalLogger.shared.error("realtime_microphone_streaming receive_failed error=\(error.localizedDescription)")
                    self.stopAudioEngine()
                    self.webSocketTask = nil
                    if let continuation = self.finalContinuation {
                        self.finalContinuation = nil
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let text: String?
        switch message {
        case .string(let string): text = string
        case .data(let data): text = String(data: data, encoding: .utf8)
        @unknown default: text = nil
        }
        guard let text else { return }
        handleEventText(text)
    }

    private func handleEventText(_ text: String) {
        guard let data = text.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let type = json["type"] as? String ?? "unknown"
        if type == "error" {
            LocalLogger.shared.info("realtime_event type=\(type) payload=\(text)")
        } else if type == "session.created" || type == "session.updated" || type.contains("transcription.completed") || type.contains("input_audio_buffer.committed") {
            LocalLogger.shared.info("realtime_event type=\(type)")
        }

        if type.contains("delta"), let delta = extractText(from: json) {
            partialTranscript += delta
        }

        if type.contains("completed") || type.contains("complete") {
            if let final = extractText(from: json), !final.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appendFinalTranscript(final)
            }
            if let continuation = finalContinuation, !finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                finalContinuation = nil
                continuation.resume(returning: makeRealtimeResult(text: finalTranscript))
                webSocketTask?.cancel(with: .normalClosure, reason: nil)
                webSocketTask = nil
                status = "Realtime transcript completed."
            }
        }

        if type == "error" {
            LocalLogger.shared.error("realtime_server_error event=\(text)")
            stopAudioEngine()
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            webSocketTask = nil
            if let continuation = finalContinuation {
                finalContinuation = nil
                continuation.resume(throwing: RealtimeTranscriptionError.serverEvent(text))
            }
        }
    }

    private func appendFinalTranscript(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if finalTranscript.isEmpty {
            finalTranscript = trimmed
        } else {
            finalTranscript += " " + trimmed
        }
    }

    private func extractText(from json: [String: Any]) -> String? {
        for key in ["transcript", "text", "delta"] {
            if let value = json[key] as? String { return value }
        }
        if let item = json["item"] as? [String: Any] { return extractText(from: item) }
        if let content = json["content"] as? [[String: Any]] {
            return content.compactMap { extractText(from: $0) }.joined()
        }
        return nil
    }

    private func makeRealtimeResult(text: String) -> TranscriptionResult {
        TranscriptionResult(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            durationMs: Int(Date().timeIntervalSince(startedAt ?? Date()) * 1000),
            model: context?.model ?? "realtime",
            isPartial: false
        )
    }

    private func sendJSON(_ object: [String: Any]) async throws {
        guard let webSocketTask else { throw RealtimeTranscriptionError.sessionNotStarted }
        let data = try JSONSerialization.data(withJSONObject: object)
        let string = String(decoding: data, as: UTF8.self)
        try await webSocketTask.send(.string(string))
    }

    private func makeMultipartBody(boundary: String, model: String, audioURL: URL, audioData: Data) -> Data {
        var body = Data()
        body.appendFormField(name: "model", value: model, boundary: boundary)
        body.appendFormField(name: "response_format", value: "text", boundary: boundary)
        body.appendFileField(name: "file", filename: audioURL.lastPathComponent, mimeType: mimeType(for: audioURL), data: audioData, boundary: boundary)
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav": "audio/wav"
        case "mp3": "audio/mpeg"
        case "m4a", "mp4": "audio/mp4"
        case "webm": "audio/webm"
        case "ogg": "audio/ogg"
        case "flac": "audio/flac"
        default: "application/octet-stream"
        }
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { throw TranscriptionError.networkError("Invalid network response.") }
        switch httpResponse.statusCode {
        case 200..<300: return
        case 401, 403: throw TranscriptionError.invalidAPIKey
        case 429: throw TranscriptionError.rateLimit
        case 400, 415: throw TranscriptionError.unsupportedAudio("Unsupported audio or request.")
        default: throw TranscriptionError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
}

enum RealtimeTranscriptionError: LocalizedError {
    case sessionNotStarted
    case finalTranscriptTimeout
    case notEnoughAudioSent
    case serverEvent(String)

    var errorDescription: String? {
        switch self {
        case .sessionNotStarted:
            "Realtime microphone session is not started."
        case .finalTranscriptTimeout:
            "Realtime microphone streaming did not return a final transcript in time."
        case .notEnoughAudioSent:
            "Realtime microphone streaming did not receive enough audio before release."
        case .serverEvent(let event):
            "Realtime server error: \(event)"
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) { append(Data(string.utf8)) }

    mutating func appendFormField(name: String, value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    mutating func appendFileField(name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        appendString("\r\n")
    }
}
