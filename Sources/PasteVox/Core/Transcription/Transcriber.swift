import Foundation

protocol Transcriber {
    func transcribe(audioURL: URL, context: TranscriptionContext) async throws -> TranscriptionResult
}

struct TranscriptionContext {
    let promptMode: PromptMode
    let model: String
}
