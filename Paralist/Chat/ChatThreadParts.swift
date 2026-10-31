// Zusammenhang: Chat/ChatThreadPage.swift, Chat/ChatMascotStage.swift, Chat/ChatEngine.swift (ChatAvailability, ChatFailure), Components/Chips.swift, Entries/TypeLook.swift, Theme/Dimens.swift (ChatDimens), Shell/Router.swift (push), Shell/RouterSplit.swift (DetailPane, push(from:), leave)
import ParalistCore
import SwiftUI
import UIKit

struct ChatNotice: View {
    let text: String
    var icon = AppIcons.info
    var action: (label: String, run: () -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon).foregroundStyle(Palette.onSurfaceVariant)
                Text(text).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            }
            if let action {
                Button(action.label, action: action.run)
                    .font(Typo.labelLarge)
                    .buttonStyle(.glass)
                    .padding(.leading, 26)
            }
        }
        .padding(.horizontal, ChatDimens.bubblePadH)
        .padding(.vertical, ChatDimens.bubblePadV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: ChatDimens.bubbleRadius))
    }
}

struct ChatAvailabilityNotice: View {
    let availability: ChatAvailability
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch availability {
        case .ready:
            EmptyView()
        case .notEligible:
            ChatNotice(text: L.s("chat_unavailable_device"))
        case .loading:
            ChatNotice(text: L.s("chat_unavailable_loading"), icon: AppIcons.download)
        case .off:
            ChatNotice(text: L.s("chat_unavailable_off"), action: (L.s("chat_open_settings"), {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }))
        }
    }
}

enum ChatFailureText {
    static func key(_ failure: ChatFailure) -> String {
        switch failure {
        case .guardrail: return "chat_error_guardrail"
        case .context: return "chat_error_context"
        case .language: return "chat_error_language"
        case .cancelled: return "chat_error_cancelled"
        case .loading: return "chat_unavailable_loading"
        case .generic: return "chat_error_generic"
        }
    }
}

struct ChatSuggestions: View {
    let project: String?
    let pick: (String) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(prompts, id: \.self) { text in
                Button { pick(text) } label: {
                    Text(text).font(Typo.bodyMedium).multilineTextAlignment(.trailing)
                        .padding(.horizontal, ChatDimens.bubblePadH)
                        .padding(.vertical, ChatDimens.bubblePadV)
                }
                .buttonStyle(.glass)
                .foregroundStyle(Palette.onSurface)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var prompts: [String] {
        [L.s("chat_suggest_week"), project.map { L.f("chat_suggest_project", $0) }, L.s("chat_suggest_overdue")].compactMap { $0 }
    }
}

struct ChatEntryChips: View {
    let ids: [String]
    var label: String?
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.detailPane) private var pane

    var body: some View {
        let entries = ids.compactMap { model.entry($0) }
        if !entries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let label {
                        Text(label).font(Typo.labelMedium).foregroundStyle(Palette.muted)
                    }
                    ForEach(entries) { entry in
                        let look = TypeLook.of(entry)
                        Button { router.push(.entry(entry.id), from: pane) } label: {
                            HStack(spacing: 6) {
                                GlyphIcon(look.icon.outlined, size: 14).foregroundStyle(look.color)
                                Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title).font(Typo.labelLarge).lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: ChatDimens.chipHeight)
                            .background(Palette.surfaceContainer, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.onSurface)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}
