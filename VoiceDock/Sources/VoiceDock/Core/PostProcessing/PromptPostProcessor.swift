import Foundation

struct PostProcessingResult {
    let text: String
    let durationMs: Int
    let model: String
    let mode: PromptMode
    let isRiskyTerminalCommand: Bool
}

final class PromptPostProcessor {
    private let apiKeyProvider: () throws -> String?
    private let session: URLSession

    init(
        apiKeyProvider: @escaping () throws -> String? = { try KeychainStore.shared.loadOpenAIAPIKey() },
        session: URLSession = .shared
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    func process(text: String, mode: PromptMode, model: String, maxOutputTokens: Int) async throws -> PostProcessingResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PostProcessingError.emptyInput }

        if mode == .rawDictation {
            return PostProcessingResult(text: trimmed, durationMs: 0, model: "none", mode: mode, isRiskyTerminalCommand: false)
        }

        let startedAt = Date()
        guard let apiKey = try apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "temperature": 0,
            "max_tokens": maxOutputTokens,
            "messages": [
                ["role": "system", "content": systemInstruction(for: mode)],
                ["role": "user", "content": trimmed]
            ]
        ])

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw PostProcessingError.invalidResponse
        }

        let output = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { throw PostProcessingError.emptyOutput }

        return PostProcessingResult(
            text: output,
            durationMs: Int(Date().timeIntervalSince(startedAt) * 1000),
            model: model,
            mode: mode,
            isRiskyTerminalCommand: SafetyClassifier.isRiskyTerminalCommandOutput(output)
        )
    }

    private func systemInstruction(for mode: PromptMode) -> String {
        switch mode {
        case .rawDictation:
            return "Верни текст без изменений."
        case .agentPrompt:
            return """
            Ты преобразуешь сырую расшифровку голоса в чёткий промпт для coding agent.
            Пиши на русском.
            Не выдумывай факты.
            Сохраняй технические термины, имена файлов, пути, команды, URL и версии.
            Убирай оговорки и мусор.
            Структурируй только если это помогает.
            Не превращай текст в email.
            """
        case .ralphPrompt:
            return """
            Ты преобразуешь сырую расшифровку голоса в RALPH-промпт для coding agent.
            Пиши на русском.
            Структура:
            - Роль
            - Цель
            - Контекст
            - Ограничения
            - Фазы
            - Acceptance criteria
            - Stop points для ручной проверки
            Не выдумывай неизвестные детали.
            Если пользователь говорит грубо или хаотично, сохрани смысл, но сделай задачу исполнимой.
            """
        case .terminalCommand:
            return """
            Ты преобразуешь речь в shell-команду или короткий набор команд.
            Верни только команду без markdown, если команда безопасная.
            Если команда может удалить данные, изменить систему, снести контейнеры/volumes, отправить секреты, поменять remote state или выполнить network/destructive action — не выдавай команду для автопаста.
            Вместо этого верни ровно:
            RISKY_COMMAND_PREVIEW
            <команда>
            <почему рискованно>
            """
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostProcessingError.networkError("Invalid network response.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw TranscriptionError.invalidAPIKey }
            if httpResponse.statusCode == 429 { throw TranscriptionError.rateLimit }
            throw PostProcessingError.networkError(errorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    private func errorMessage(from data: Data) -> String? {
        if
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
        { return message }
        return String(data: data, encoding: .utf8)
    }
}

enum PostProcessingError: LocalizedError {
    case emptyInput
    case emptyOutput
    case invalidResponse
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput: "Post-processing input is empty."
        case .emptyOutput: "Post-processing returned empty output."
        case .invalidResponse: "Post-processing returned invalid response."
        case .networkError(let message): "Post-processing error: \(message)"
        }
    }
}
