// FineTune/Views/Settings/Components/SettingsRow.swift
import SwiftUI

@MainActor
struct SettingsRow<Trailing: View>: View {
    private let title: Text
    private let description: Text?
    @ViewBuilder private let trailing: () -> Trailing

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = Text(title)
        self.description = description.map { Text($0) }
        self.trailing = trailing
    }

    /// Runtime strings have already been localized at their source.
    init(
        localizedTitle title: String,
        description: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = Text(verbatim: title)
        self.description = description.map { Text(verbatim: $0) }
        self.trailing = trailing
    }

    init(
        _ title: LocalizedStringKey,
        localizedDescription description: String,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = Text(title)
        self.description = Text(verbatim: description)
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                if let description {
                    description
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 16)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

/// Hairline divider sized to fit between `SettingsRow`s inside a
/// `SettingsSection`. Inset from the leading edge so it doesn't touch the
/// container border.
struct SettingsRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
    }
}
