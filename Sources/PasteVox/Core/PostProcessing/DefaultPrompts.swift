import Foundation

/// Built-in default system prompts for post-processed modes and writing styles,
/// in the two in-app languages ("en"/"ru"). A per-mode override in AppSettings
/// wins over these; the language follows AppSettings.resolvedPromptLanguage.
enum DefaultPrompts {
    /// Base system prompt for a post-processed mode, in the given language.
    static func modePrompt(_ mode: PromptMode, language: String) -> String {
        let ru = language == "ru"
        switch mode {
        case .rawDictation:
            return ru ? "Верни текст без изменений." : "Return the text unchanged."
        case .agentPrompt:
            return ru ? """
            Ты преобразуешь сырую расшифровку голоса в чёткий промпт для coding agent.
            Пиши на русском.
            Не выдумывай факты.
            Сохраняй технические термины, имена файлов, пути, команды, URL и версии.
            Убирай оговорки и мусор.
            Структурируй только если это помогает.
            Не превращай текст в email.
            """ : """
            You turn a raw voice transcript into a clear prompt for a coding agent.
            Write in English.
            Do not invent facts.
            Preserve technical terms, file names, paths, commands, URLs and versions.
            Strip filler and false starts.
            Add structure only when it helps.
            Do not turn the text into an email.
            """
        case .ralphPrompt:
            return ru ? """
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
            """ : """
            You turn a raw voice transcript into a RALPH prompt for a coding agent.
            Write in English.
            Structure:
            - Role
            - Goal
            - Context
            - Constraints
            - Phases
            - Acceptance criteria
            - Stop points for manual review
            Do not invent unknown details.
            If the user is blunt or chaotic, keep the meaning but make the task executable.
            """
        case .terminalCommand:
            // NOTE: the RISKY_COMMAND_PREVIEW sentinel must stay verbatim in every
            // language — SafetyClassifier keys the safety gate off it.
            return ru ? """
            Ты преобразуешь речь в shell-команду или короткий набор команд.
            Верни только команду без markdown, если команда безопасная.
            Если команда может удалить данные, изменить систему, снести контейнеры/volumes, отправить секреты, поменять remote state или выполнить network/destructive action — не выдавай команду для автопаста.
            Вместо этого верни ровно:
            RISKY_COMMAND_PREVIEW
            <команда>
            <почему рискованно>
            """ : """
            You turn speech into a shell command or a short set of commands.
            Return only the command, without markdown, if it is safe.
            If the command could delete data, modify the system, tear down containers/volumes, leak secrets, change remote state, or perform a network/destructive action — do not return it for auto-paste.
            Instead return exactly:
            RISKY_COMMAND_PREVIEW
            <command>
            <why it is risky>
            """
        }
    }

    /// Writing-style modifier instruction, in the given language.
    static func styleInstruction(_ style: WritingStyle, language: String) -> String {
        let ru = language == "ru"
        switch style {
        case .default:
            return ru ? "Сохраняй естественный стиль пользователя."
                      : "Keep the user's natural style."
        case .concise:
            return ru ? "Сделай результат кратким, плотным и без лишних слов."
                      : "Make the result short, dense and free of filler."
        case .friendly:
            return ru ? "Сделай тон дружелюбным, живым и понятным, без чрезмерной официальности."
                      : "Make the tone friendly, lively and clear, without being overly formal."
        case .formal:
            return ru ? "Сделай тон профессиональным, аккуратным и формальным."
                      : "Make the tone professional, careful and formal."
        case .codingAgent:
            return ru ? "Сформулируй как чёткую задачу для coding agent: цель, контекст, ограничения, критерии готовности."
                      : "Phrase it as a clear coding-agent task: goal, context, constraints, acceptance criteria."
        case .chat:
            return ru ? "Сформулируй как короткое сообщение для чата/мессенджера."
                      : "Phrase it as a short chat/messenger message."
        case .email:
            return ru ? "Сформулируй как аккуратный email или email-фрагмент с уместным тоном."
                      : "Phrase it as a tidy email or email snippet with an appropriate tone."
        }
    }

    /// The "Output style: …" suffix appended to agent/RALPH prompts.
    static func styleSuffix(_ style: WritingStyle, language: String) -> String {
        let label = language == "ru" ? "Стиль вывода:" : "Output style:"
        return "\n\n\(label) \(styleInstruction(style, language: language))"
    }
}
