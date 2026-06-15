import XCTest
@testable import PasteVox

final class LocalizationTests: XCTestCase {
    override func tearDown() {
        L10n.languageCode = "en"
        super.tearDown()
    }

    func testRussianTranslationsLoadFromBundle() {
        L10n.languageCode = "ru"
        XCTAssertEqual(T("Settings"), "Настройки")
        XCTAssertEqual(T("Listening"), "Слушаю")
        XCTAssertEqual(T("Behavior"), "Поведение")
        XCTAssertEqual(T("Microphone"), "Микрофон")
        XCTAssertEqual(T("Snippets"), "Сниппеты")
        XCTAssertEqual(T("Match system"), "Как в системе")
    }

    func testFormatSpecifiersPreservedInRussian() {
        L10n.languageCode = "ru"
        XCTAssertEqual(T("Mode: %@"), "Режим: %@")
        XCTAssertEqual(T("Imported %d."), "Импортировано: %d.")
    }

    func testEnglishUsesSourceText() {
        L10n.languageCode = "en"
        XCTAssertEqual(T("Settings"), "Settings")
        XCTAssertEqual(T("Listening"), "Listening")
    }

    func testKeptEnglishTermsFallBackToKey() {
        L10n.languageCode = "ru"
        // Product/brand terms are intentionally not translated -> fall back to the English key.
        XCTAssertEqual(T("Keychain"), "Keychain")
        XCTAssertEqual(T("Home"), "Home")
        XCTAssertEqual(T("Fn+1 Raw"), "Fn+1 Raw")
    }

    func testResolvedLanguageFromSystemPreference() {
        XCTAssertEqual(AppLanguage.en.resolvedCode, "en")
        XCTAssertEqual(AppLanguage.ru.resolvedCode, "ru")
        // .system resolves to one of the supported codes.
        XCTAssertTrue(["en", "ru"].contains(AppLanguage.system.resolvedCode))
    }
}
