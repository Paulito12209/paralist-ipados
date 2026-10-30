// Zusammenhang: Chat/ChatMentionParts.swift (ChatMentionChips), ParalistCore Chat/ChatThinking.swift, App/AppPrefs.swift (chatThinking), Chat/ChatThreadPage.swift, Chat/ChatImageParts.swift, Chat/ChatImagePickers.swift, Files/AttachmentImporter.swift, Composer/ComposerSheet.swift (gleiche Karte), Composer/DictationSheet.swift, Theme/Dimens.swift (ComposerDimens, ChatDimens), Icons/AppIcons.swift
import ParalistCore
import PhotosUI
import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    @Binding var image: Attachment?
    @Binding var mentions: [String]
    var focused: FocusState<Bool>.Binding
    @Binding var thinking: ChatThinking
    let showsThinking: Bool
    let enabled: Bool
    let busy: Bool
    let send: () -> Void
    let stop: () -> Void
    @Environment(AppModel.self) private var model
    @State private var dictating = false
    @State private var pickingPhoto = false
    @State private var photo: PhotosPickerItem?
    @State private var capture: ChatCapture?

    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var ready: Bool { enabled && !busy && (hasText || image != nil || !mentions.isEmpty) }
    private var dictates: Bool { enabled && !busy && !hasText && image == nil && mentions.isEmpty }

    @State private var cardWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    private var stacked: Bool {
        if showsThinking || text.contains("\n") { return true }
        let room = cardWidth - (ComposerDimens.inset * 2 + ComposerDimens.button) * 2
        return cardWidth > 0 && textWidth > room
    }

    private var maxLines: Int {
        let line = UIFontMetrics(forTextStyle: .body).scaledFont(for: Typo.uiFont(16)).lineHeight
        return max(1, Int(ChatDimens.inputMaxHeight / line))
    }

    var body: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .center, spacing: ComposerDimens.inset))
        VStack(alignment: .leading, spacing: 0) {
            if !mentions.isEmpty {
                ChatMentionChips(ids: mentions) { id in mentions.removeAll { $0 == id } }
                    .padding(.leading, ComposerDimens.textInset)
                    .padding(.top, ComposerDimens.inset + ChatDimens.imageRowGap)
            }
            if let image {
                ChatImageTile(url: model.library.store.attachmentFile(image.hash)) { discard(image) }
                    .padding(.leading, ComposerDimens.textInset)
                    .padding(.top, ComposerDimens.inset + ChatDimens.imageRowGap)
            }
            layout {
                if !stacked { imageButton }
                TextField(L.s("chat_input_placeholder"), text: $text, axis: .vertical)
                    .lineLimit(1...maxLines)
                    .font(Typo.bodyLarge)
                    .foregroundStyle(Palette.onSurface)
                    .focused(focused)
                    .disabled(!enabled)
                    .padding(.leading, stacked ? ComposerDimens.textInset : 0)
                    .padding(.trailing, stacked ? ComposerDimens.textInset : 0)
                    .padding(.top, stacked ? 14 : 0)
                    .background(alignment: .leading) {
                        Text(text).font(Typo.bodyLarge).lineLimit(1).fixedSize().hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
                    }
                HStack(spacing: 0) {
                    if stacked { imageButton.padding(.trailing, 4) }
                    if showsThinking { thinkingMenu }
                    if stacked { Spacer(minLength: 0) }
                    actionButton
                }
                .padding(stacked ? ComposerDimens.inset : 0)
            }
            .padding(.vertical, stacked ? 0 : ComposerDimens.inset)
            .padding(.horizontal, stacked ? 0 : ComposerDimens.inset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
        .animation(Motion.short, value: stacked)
        .animation(Motion.short, value: image)
        .animation(Motion.short, value: mentions)
        .background(Palette.composerCard, in: RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous)
                .strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1)
        }
        .padding(.horizontal, ComposerDimens.edge)
        .padding(.bottom, ComposerDimens.inset)
        .sheet(isPresented: $dictating) {
            DictationSheet { spoken in
                text = text.isEmpty ? spoken : text + " " + spoken
            }
        }
        .photosPicker(isPresented: $pickingPhoto, selection: $photo, matching: .images)
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                attach(try? await item.loadTransferable(type: Data.self))
                photo = nil
            }
        }
        .fullScreenCover(item: $capture) { which in
            Group {
                if which == .camera {
                    ChatCameraPicker { data in
                        capture = nil
                        attach(data)
                    }
                } else {
                    ChatDocumentScanner { data in
                        capture = nil
                        attach(data)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    private var imageButton: some View {
        ChatImageButton(enabled: enabled && !busy, pickPhoto: { pickingPhoto = true }) { which in
            guard which.available else { return model.say(L.s("capture_camera_unavailable")) }
            capture = which
        }
    }

    private func attach(_ data: Data?) {
        guard let data else { return }
        switch AttachmentImporter.importData(data, name: "bild.jpg", into: model.library.store) {
        case .success(let attachment):
            if let old = image, old.hash != attachment.hash { model.chats.discardImage(old.hash) }
            image = attachment
        case .failure(let failure):
            model.say(failure.message)
        }
    }

    private func discard(_ attachment: Attachment) {
        image = nil
        model.chats.discardImage(attachment.hash)
    }

    private var thinkingMenu: some View {
        Menu {
            Section(L.s("chat_thinking_title")) {
                ForEach(ChatThinking.allCases, id: \.self) { level in
                    Toggle(isOn: Binding(get: { thinking == level }, set: { if $0 { thinking = level } })) {
                        Text(L.s(ThinkingLook.label(level)))
                        Text(L.s(ThinkingLook.hint(level)))
                        Image(systemName: ThinkingLook.icon(level))
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: ThinkingLook.icon(thinking)).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.onSurfaceVariant)
                Text(L.s(ThinkingLook.label(thinking))).font(Typo.labelLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                Image(systemName: AppIcons.caret).font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
            }
            .padding(.horizontal, 10)
            .frame(height: ComposerDimens.button)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(L.s("chat_thinking_title"))
    }

    private var actionButton: some View {
        let icon = busy ? AppIcons.stop : (dictates ? AppIcons.audio : AppIcons.send)
        let filled = busy || ready
        return Button {
            if busy { stop() } else if dictates { dictating = true } else { send() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(filled ? Palette.onPrimary : Palette.onSurface)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                .background(filled ? Palette.primary : Palette.composerButton, in: Circle())
                .opacity(busy || ready || dictates ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!busy && !ready && !dictates)
        .animation(Motion.short, value: icon)
        .accessibilityLabel(L.s(busy ? "chat_stop" : (dictates ? "dictation_title" : "chat_send")))
    }
}

enum ThinkingLook {
    static func label(_ level: ChatThinking) -> String {
        switch level {
        case .fast: return "chat_thinking_fast"
        case .balanced: return "chat_thinking_balanced"
        case .thorough: return "chat_thinking_thorough"
        }
    }

    static func hint(_ level: ChatThinking) -> String {
        switch level {
        case .fast: return "chat_thinking_fast_hint"
        case .balanced: return "chat_thinking_balanced_hint"
        case .thorough: return "chat_thinking_thorough_hint"
        }
    }

    static func icon(_ level: ChatThinking) -> String {
        switch level {
        case .fast: return AppIcons.thinkingFast
        case .balanced: return AppIcons.thinkingBalanced
        case .thorough: return AppIcons.thinkingThorough
        }
    }
}
