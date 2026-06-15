import Foundation

/// App-facing language selection. `.system` follows the macOS preferred language,
/// falling back to the closest supported locale (en/ru).
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case en
    case ru

    var id: String { rawValue }

    /// Name shown in the language picker. Concrete languages use their own endonym.
    var displayName: String {
        switch self {
        case .system: return T("Match system")
        case .en: return "English"
        case .ru: return "Русский"
        }
    }

    /// Concrete locale code ("en"/"ru") used to load the strings bundle.
    var resolvedCode: String {
        switch self {
        case .system:
            let preferred = (Locale.preferredLanguages.first ?? "en").lowercased()
            return preferred.hasPrefix("ru") ? "ru" : "en"
        case .en: return "en"
        case .ru: return "ru"
        }
    }
}

/// Lightweight runtime localization that supports an in-app language override
/// (not just the system locale). Strings are keyed by their English source text.
enum L10n {
    static let storageKey = "appLanguage"

    /// Resolved language code currently in effect. Kept in sync by `AppSettings`.
    static var languageCode: String = {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.system.rawValue
        return (AppLanguage(rawValue: raw) ?? .system).resolvedCode
    }()

    private static var bundleCache: [String: Bundle] = [:]

    private static func bundle(for code: String) -> Bundle {
        if let cached = bundleCache[code] { return cached }
        if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            bundleCache[code] = bundle
            return bundle
        }
        return .module
    }

    /// Localize an English source string for the current app language.
    /// Falls back to the English key when no translation is present.
    static func t(_ key: String) -> String {
        bundle(for: languageCode).localizedString(forKey: key, value: key, table: nil)
    }
}

/// Shorthand for `L10n.t`. Use everywhere a user-facing string is produced:
/// `Text(T("Save Snippet"))`, `NSMenuItem(title: T("Quit PasteVox"), ...)`, etc.
func T(_ key: String) -> String { L10n.t(key) }

extension Notification.Name {
    /// Posted after the in-app language changes so AppKit surfaces (status menu,
    /// HUD, already-open windows) can refresh their text.
    static let appLanguageChanged = Notification.Name("PasteVox.appLanguageChanged")
}
