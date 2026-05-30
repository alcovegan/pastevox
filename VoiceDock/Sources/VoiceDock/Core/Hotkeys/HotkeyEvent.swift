import Foundation

enum HotkeyEvent: String {
    case pressed
    case released
}

enum HotkeyKind: String, CaseIterable, Identifiable {
    case fnHold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fnHold: "Fn/Globe hold"
        }
    }
}
