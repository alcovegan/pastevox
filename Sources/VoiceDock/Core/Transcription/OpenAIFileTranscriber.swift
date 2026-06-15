import Foundation

final class OpenAIFileTranscriber: Transcriber {
    private let apiKeyProvider: () throws -> String?
    private let session: URLSession

    init(
        apiKeyProvider: @escaping () throws -> String? = { try KeychainStore.shared.loadOpenAIAPIKey() },
        session: URLSession = .shared
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    func testAPIKey() async throws {
        guard let apiKey = try apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (_, response) = try await session.data(for: request)
        try validate(response: response, data: nil)
    }

    func transcribe(audioURL: URL, context: TranscriptionContext) async throws -> TranscriptionResult {
        let startedAt = Date()
        guard let apiKey = try apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
        } catch {
            throw TranscriptionError.unsupportedAudio("Could not read selected audio file.")
        }

        guard !audioData.isEmpty else {
            throw TranscriptionError.unsupportedAudio("Selected audio file is empty.")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            model: context.model,
            prompt: DictionaryStore.promptText(),
            audioURL: audioURL,
            audioData: audioData
        )

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw TranscriptionError.emptyTranscript
        }

        return TranscriptionResult(
            text: text,
            durationMs: Int(Date().timeIntervalSince(startedAt) * 1000),
            model: context.model,
            isPartial: false
        )
    }

    private func makeMultipartBody(boundary: String, model: String, prompt: String?, audioURL: URL, audioData: Data) -> Data {
        var body = Data()
        body.appendFormField(name: "model", value: model, boundary: boundary)
        body.appendFormField(name: "response_format", value: "text", boundary: boundary)
        if let prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body.appendFormField(name: "prompt", value: prompt, boundary: boundary)
        }
        body.appendFileField(
            name: "file",
            filename: audioURL.lastPathComponent,
            mimeType: mimeType(for: audioURL),
            data: audioData,
            boundary: boundary
        )
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav": "audio/wav"
        case "mp3": "audio/mpeg"
        case "m4a": "audio/mp4"
        case "mp4": "audio/mp4"
        case "webm": "audio/webm"
        case "ogg": "audio/ogg"
        case "flac": "audio/flac"
        default: "application/octet-stream"
        }
    }

    private func validate(response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError("Invalid network response.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw TranscriptionError.invalidAPIKey
        case 429:
            throw TranscriptionError.rateLimit
        case 400, 415:
            throw TranscriptionError.unsupportedAudio(errorMessage(from: data) ?? "Unsupported audio or request.")
        default:
            throw TranscriptionError.networkError(errorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    private func errorMessage(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        if
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
        {
            return message
        }
        return String(data: data, encoding: .utf8)
    }
}

enum TranscriptionError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case unsupportedAudio(String)
    case rateLimit
    case emptyTranscript
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "OpenAI API key is missing. Save it in Settings first."
        case .invalidAPIKey:
            "OpenAI API key is invalid or unauthorized."
        case .networkError(let message):
            "Network/OpenAI error: \(message)"
        case .unsupportedAudio(let message):
            "Unsupported audio: \(message)"
        case .rateLimit:
            "OpenAI rate limit reached. Try again later."
        case .emptyTranscript:
            "OpenAI returned an empty transcript."
        case .notImplemented:
            "Not implemented yet."
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }

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
