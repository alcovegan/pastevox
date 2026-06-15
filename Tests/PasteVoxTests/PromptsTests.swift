import XCTest
@testable import PasteVox

final class PromptsTests: XCTestCase {
    func testDefaultModePromptFollowsLanguage() {
        XCTAssertTrue(DefaultPrompts.modePrompt(.ralphPrompt, language: "en").contains("RALPH prompt"))
        XCTAssertTrue(DefaultPrompts.modePrompt(.ralphPrompt, language: "ru").contains("RALPH-промпт"))
        XCTAssertTrue(DefaultPrompts.modePrompt(.agentPrompt, language: "en").contains("Write in English"))
        XCTAssertTrue(DefaultPrompts.modePrompt(.agentPrompt, language: "ru").contains("Пиши на русском"))
    }

    func testTerminalSentinelPreservedInBothLanguages() {
        // SafetyClassifier keys the gate off this sentinel — it must stay verbatim.
        XCTAssertTrue(DefaultPrompts.modePrompt(.terminalCommand, language: "en").contains("RISKY_COMMAND_PREVIEW"))
        XCTAssertTrue(DefaultPrompts.modePrompt(.terminalCommand, language: "ru").contains("RISKY_COMMAND_PREVIEW"))
    }

    func testStyleSuffixFollowsLanguage() {
        XCTAssertTrue(DefaultPrompts.styleSuffix(.concise, language: "en").contains("Output style:"))
        XCTAssertTrue(DefaultPrompts.styleSuffix(.concise, language: "ru").contains("Стиль вывода:"))
    }

    @MainActor
    func testPromptOverridePrecedenceAndReset() {
        let settings = AppSettings.shared
        settings.resetPromptOverride(for: .ralphPrompt)
        XCTAssertNil(settings.promptOverride(for: .ralphPrompt))
        XCTAssertFalse(settings.hasPromptOverride(for: .ralphPrompt))

        settings.setPromptOverride("MY CUSTOM RALPH PROMPT", for: .ralphPrompt)
        XCTAssertEqual(settings.promptOverride(for: .ralphPrompt), "MY CUSTOM RALPH PROMPT")
        XCTAssertTrue(settings.hasPromptOverride(for: .ralphPrompt))

        // Setting the exact current-language default clears the override.
        settings.setPromptOverride(DefaultPrompts.modePrompt(.ralphPrompt, language: settings.resolvedPromptLanguage), for: .ralphPrompt)
        XCTAssertNil(settings.promptOverride(for: .ralphPrompt))

        settings.setPromptOverride("temp", for: .ralphPrompt)
        settings.resetPromptOverride(for: .ralphPrompt)
        XCTAssertNil(settings.promptOverride(for: .ralphPrompt))
    }

    @MainActor
    func testResolvedPromptLanguage() {
        let settings = AppSettings.shared
        let original = settings.promptLanguageMode
        settings.promptLanguageMode = .ru
        XCTAssertEqual(settings.resolvedPromptLanguage, "ru")
        settings.promptLanguageMode = .en
        XCTAssertEqual(settings.resolvedPromptLanguage, "en")
        settings.promptLanguageMode = .followApp
        XCTAssertTrue(["en", "ru"].contains(settings.resolvedPromptLanguage))
        settings.promptLanguageMode = original
    }
}
