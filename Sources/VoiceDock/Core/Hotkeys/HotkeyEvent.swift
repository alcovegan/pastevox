import Foundation

enum HotkeyEvent: String {
    case pressed
    case released
}

enum HotkeyKind: String, CaseIterable, Identifiable, Codable {
    case fnHold
    case rightOptionHold
    case rightCommandHold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fnHold: "Fn/Globe hold"
        case .rightOptionHold: "Right Option hold"
        case .rightCommandHold: "Right Command hold"
        }
    }

    var shortTitle: String {
        switch self {
        case .fnHold: "Fn/Globe"
        case .rightOptionHold: "Right Option"
        case .rightCommandHold: "Right Command"
        }
    }
}
