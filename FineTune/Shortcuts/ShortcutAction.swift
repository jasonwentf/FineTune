// FineTune/Shortcuts/ShortcutAction.swift
import Foundation

/// Actions that can be bound to a user-recordable global keyboard shortcut.
///
/// Adding a new action here is a single enum case + a corresponding arm
/// in `ShortcutsRegistry.dispatch(_:)`. The `rawValue` is the persistence key
/// in `AppSettings.customShortcuts` and must be stable across releases.
enum ShortcutAction: String, CaseIterable, Codable, Sendable {
    case togglePopup
    case targetAppVolumeUp = "frontmostAppVolumeUp"
    case targetAppVolumeDown = "frontmostAppVolumeDown"
    case targetAppMuteToggle = "frontmostAppMuteToggle"

    var displayName: String {
        switch self {
        case .togglePopup: String(localized: "Toggle FineTune Popup")
        case .targetAppVolumeUp: String(localized: "App Volume Up")
        case .targetAppVolumeDown: String(localized: "App Volume Down")
        case .targetAppMuteToggle: String(localized: "App Mute")
        }
    }

    /// Whether holding the chord should keep firing the action while held,
    /// matching macOS media-key auto-repeat. Toggles must not repeat
    /// (would flip-flop state every interval).
    var supportsRepeat: Bool {
        switch self {
        case .targetAppVolumeUp, .targetAppVolumeDown: true
        case .togglePopup, .targetAppMuteToggle: false
        }
    }
}
