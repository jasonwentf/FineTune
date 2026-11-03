// FineTune/Settings/Types/SettingsUITypes.swift
import Foundation
import AppKit

// MARK: - App-Wide Settings Enums

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case `default` = "Default"
    case speaker = "Speaker"
    case device = "Device"
    case waveform = "Waveform"
    case equalizer = "Equalizer"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return String(localized: "Default")
        case .speaker: return String(localized: "Speaker")
        case .device: return String(localized: "Device")
        case .waveform: return String(localized: "Waveform")
        case .equalizer: return String(localized: "Equalizer")
        }
    }

    /// The icon name - either asset catalog name or SF Symbol
    var iconName: String {
        switch self {
        case .default: return "MenuBarIcon"
        case .speaker: return "speaker.wave.2.fill"
        case .device: return "headphones"
        case .waveform: return "waveform"
        case .equalizer: return "slider.vertical.3"
        }
    }

    /// Whether this uses an SF Symbol (vs asset catalog image)
    var isSystemSymbol: Bool {
        self != .default
    }
}

// MARK: - HUD Style

/// Style of the on-screen HUD shown when media keys drive FineTune's volume.
/// `.tahoe` renders a small top-right pill; `.classic` renders a center-bottom panel
/// with 16 segment tiles matching Apple's pre-Tahoe HUD aesthetic.
enum HUDStyle: String, Codable, CaseIterable, Identifiable {
    case tahoe
    case classic

    var id: String { rawValue }
}

// MARK: - Appearance Preference

/// User preference for app appearance. `.system` follows macOS appearance live;
/// `.light` and `.dark` lock the override regardless of system setting.
enum AppearancePreference: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case system
    case light
    case dark

    var id: String { rawValue }

    var description: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }
}

// MARK: - Language Preference

/// Interface language. `.system` follows macOS (a Chinese system gets Chinese, anything
/// else gets English); the other cases pin a language regardless of the system.
enum LanguagePreference: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    /// Code written into the app's `AppleLanguages`, or `nil` to follow the system.
    var languageCode: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .simplifiedChinese: return "zh-Hans"
        }
    }

    var description: String {
        switch self {
        case .system: return String(localized: "System Default")
        case .english: return String(localized: "English")
        // Endonym: the same in every language, so it is deliberately verbatim.
        case .simplifiedChinese: return "简体中文"
        }
    }
}

/// Applies a `LanguagePreference` to the app's own preferences.
///
/// The bundle resolves its strings once, at launch, so a change only takes effect after
/// relaunching — the UI offers a restart affordance instead of pretending it is live.
enum LanguagePreferenceStore {
    static let appleLanguagesKey = "AppleLanguages"

    static func apply(_ preference: LanguagePreference, defaults: UserDefaults = .standard) {
        guard let code = preference.languageCode else {
            defaults.removeObject(forKey: appleLanguagesKey)
            return
        }
        defaults.set([code], forKey: appleLanguagesKey)
    }

    /// Relaunch the app so the new language is picked up from the bundle.
    static func relaunch() {
        let path = Bundle.main.bundleURL.path
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1; /usr/bin/open \"$1\"", "--", path]
        try? task.run()
        NSApp.terminate(nil)
    }
}

extension AppearancePreference {
    /// AppKit appearance override. `nil` means "inherit from window or app".
    /// Apply via `nsView.window?.appearance = value` for any `NSWindow`/`NSPanel`
    /// the app hosts (popup, popover, HUD).
    /// `.aqua` available since macOS 10.9; `.darkAqua` since 10.14.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Menu Bar Popup Size

enum MenuBarPopupSize: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case compact
    case comfortable
    case spacious

    var id: String { rawValue }

    var description: String {
        switch self {
        case .compact: return String(localized: "Compact")
        case .comfortable: return String(localized: "Comfortable")
        case .spacious: return String(localized: "Spacious")
        }
    }
}

struct PopupDimensions: Equatable {
    let width: CGFloat
    let contentPadding: CGFloat
    /// Ceiling on the scrollable body. Sized to stay within a 13" MacBook Air's
    /// usable height after the menu bar, since FluidMenuBarExtra does not clamp
    /// the popup against `screen.visibleFrame` vertically.
    let maxContentHeight: CGFloat
}

extension MenuBarPopupSize {
    var dimensions: PopupDimensions {
        switch self {
        case .compact:
            return PopupDimensions(
                width: 470,
                contentPadding: 12,
                maxContentHeight: 560
            )
        case .comfortable:
            return PopupDimensions(
                width: 510,
                contentPadding: 16,
                maxContentHeight: 660
            )
        case .spacious:
            return PopupDimensions(
                width: 560,
                contentPadding: 20,
                maxContentHeight: 760
            )
        }
    }
}

// MARK: - Volume Hotkey Step Size

enum VolumeHotkeyStep: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case coarse
    case normal
    case fine
    case extraFine

    var id: String { rawValue }

    var sliderDelta: Double {
        switch self {
        case .coarse:    return 1.0 / 8.0
        case .normal:    return 1.0 / 16.0
        case .fine:      return 1.0 / 32.0
        case .extraFine: return 1.0 / 64.0
        }
    }

    var description: String {
        switch self {
        case .coarse:    return String(localized: "Coarse (12.5%)")
        case .normal:    return String(localized: "Normal (6.25%)")
        case .fine:      return String(localized: "Fine (3.13%)")
        case .extraFine: return String(localized: "Extra-Fine (1.56%)")
        }
    }
}
