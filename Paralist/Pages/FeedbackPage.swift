// Zusammenhang: App/CommunityLinks.swift, Pages/SettingsPage.swift, Shell/RouteDestination.swift, Icons/AppIcons.swift
import SwiftUI

struct FeedbackPage: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: AppIcons.feedback)
                        .font(.system(size: 34))
                        .foregroundStyle(Palette.primary)
                    Text(L.s("feedback_title")).font(Typo.headlineSmall)
                    Text(L.s("feedback_intro")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                }
                .padding(.vertical, 8)
            }
            Section {
                Text(L.f("feedback_tip", version)).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            }
            Section {
                Button { openURL(CommunityLinks.discord) } label: {
                    Label(L.s("feedback_join_discord"), systemImage: AppIcons.community)
                        .font(Typo.titleMedium)
                        .foregroundStyle(Palette.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text(L.s("feedback_account_note")).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
        .tint(Palette.primary)
        .foregroundStyle(Palette.onSurface)
        .navigationTitle(L.s("page_feedback"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
