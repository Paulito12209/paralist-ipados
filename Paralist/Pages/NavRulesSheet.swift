// Zusammenhang: Pages/MenuPage.swift (Info-Knopf neben Navigation), Shell/TabSlotMenu.swift, ParalistCore Library/TabBarOrder.swift (maxTabs), Theme/Dimens.swift (InfoDimens, Dimens.sheetRadius)
import ParalistCore
import SwiftUI

struct NavRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L.s("tabbar_rules_title")).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
                    Spacer(minLength: 12)
                    Button { dismiss() } label: {
                        Image(systemName: AppIcons.clearField).font(.system(size: 22)).foregroundStyle(Palette.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("create_close"))
                }
                .padding(.bottom, 8)
                ForEach(Array(L.s("tabbar_rules").components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Dimens.sheetRadius)
        .presentationBackground(.regularMaterial)
    }
}
