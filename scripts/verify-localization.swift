#!/usr/bin/env swift
import Foundation

// Run without launching FineTune or touching audio/settings:
// swift scripts/verify-localization.swift <FineTune.app> <Localizable.xcstrings>
// Pass -AppleLanguages '("zh-Hans")' or '("en")' to verify language selection.
let args = CommandLine.arguments
precondition(args.count >= 3, "Provide the built app and source catalog paths")
let appURL = URL(fileURLWithPath: args[1])
let catalogURL = URL(fileURLWithPath: args[2])
guard let appBundle = Bundle(url: appURL),
      let resourceURL = appBundle.resourceURL,
      let english = Bundle(url: resourceURL.appendingPathComponent("en.lproj")),
      let chinese = Bundle(url: resourceURL.appendingPathComponent("zh-Hans.lproj")) else {
    fatalError("Built app must contain both en and zh-Hans localizations")
}
let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
precondition(catalog["sourceLanguage"] as? String == "en")
let strings = catalog["strings"] as! [String: [String: Any]]

func placeholders(_ value: String) -> [String] {
    let pattern = #"%(?:\d+\$)?(?:lld|llu|ld|lu|d|u|@|f|g|s|%)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(value.startIndex..., in: value)
    return regex.matches(in: value, range: range).compactMap { match in
        let token = String(value[Range(match.range, in: value)!])
        if token == "%%" { return nil }
        return token.replacingOccurrences(of: #"%\d+\$"#, with: "%", options: .regularExpression)
    }.sorted()
}

for (key, entry) in strings {
    let localizations = entry["localizations"] as! [String: [String: Any]]
    let en = localizations["en"]!["stringUnit"] as! [String: String]
    let zh = localizations["zh-Hans"]!["stringUnit"] as! [String: String]
    precondition(en["value"] == key, "English source changed: \(key)")
    precondition(zh["state"] == "translated" && !(zh["value"]?.isEmpty ?? true), "Missing translation: \(key)")
    precondition(english.localizedString(forKey: key, value: nil, table: nil) == key, "Compiled English mismatch: \(key)")
    precondition(chinese.localizedString(forKey: key, value: nil, table: nil) == zh["value"], "Compiled Chinese mismatch: \(key)")
    precondition(placeholders(key) == placeholders(zh["value"]!), "Format arguments changed: \(key)")
}

precondition(String(localized: "Multi · \(3) devices", bundle: chinese) == "多设备 · 3 台设备")
precondition(String(localized: "Multi · \(3) devices", bundle: english) == "Multi · 3 devices")
let deviceName = "AirPods Pro"
let percent = 50
precondition(String(localized: "\(deviceName), volume \(percent) percent", bundle: chinese) == "AirPods Pro，音量 50%")
precondition(String(localized: "\(deviceName), volume \(percent) percent", bundle: english) == "AirPods Pro, volume 50 percent")
precondition(String(localized: "FineTune", bundle: chinese) == "FineTune")

let languages = UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages
let selected = Bundle.preferredLocalizations(from: appBundle.localizations, forPreferences: languages)
// A command-line Swift process has no localized main bundle. Resolve the
// selected .lproj explicitly rather than inheriting the interpreter's language.
let selectedBundle = selected.first == "zh-Hans" ? chinese : english
if languages.first?.hasPrefix("zh-Hans") == true {
    precondition(selected.first == "zh-Hans", "Simplified Chinese was not selected")
    precondition(selectedBundle.localizedString(forKey: "Settings", value: nil, table: nil) == "设置")
} else if languages.first?.hasPrefix("en") == true {
    precondition(selected.first == "en", "English was not selected")
    precondition(selectedBundle.localizedString(forKey: "Settings", value: nil, table: nil) == "Settings")
}
let permissionCatalogURL = catalogURL.deletingLastPathComponent().appendingPathComponent("InfoPlist.xcstrings")
let permissionCatalog = try JSONSerialization.jsonObject(with: Data(contentsOf: permissionCatalogURL)) as! [String: Any]
let permissions = permissionCatalog["strings"] as! [String: [String: Any]]
for (key, entry) in permissions {
    let localizations = entry["localizations"] as! [String: [String: Any]]
    for (language, bundle) in [("en", english), ("zh-Hans", chinese)] {
        let unit = localizations[language]!["stringUnit"] as! [String: String]
        precondition(bundle.localizedString(forKey: key, value: nil, table: "InfoPlist") == unit["value"], "Permission translation mismatch: \(key)")
        if language == "en" {
            precondition(appBundle.infoDictionary?[key] as? String == unit["value"], "Original permission text changed: \(key)")
        }
    }
}

// When compiled into an isolated probe bundle, also check real main-bundle
// lookup, without ever launching FineTune's audio engine.
if Bundle.main.bundleURL.pathExtension == "app", selected.first == "zh-Hans" {
    precondition(String(localized: "Settings") == "设置")
} else if Bundle.main.bundleURL.pathExtension == "app", selected.first == "en" {
    precondition(String(localized: "Settings") == "Settings")
}
print("PASS: \(strings.count) bilingual keys + \(permissions.count) permission texts, compiled values, placeholders, interpolation, proper names; selected language: \(selected.first ?? "unknown")")
