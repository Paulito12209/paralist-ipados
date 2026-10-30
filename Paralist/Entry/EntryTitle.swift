// Zusammenhang: Entry/EntryCanvasPanel.swift, Entry/EntryInfoSheet.swift, Entry/TitleKeyboardBar.swift, Icons/AppIcons.swift, ParalistCore/Library/TitleEdit.swift, App/ClipboardMemory.swift
import ParalistCore
import SwiftUI
import UIKit

struct EntryTitleLine: View {
    let entry: Entry
    let onTap: () -> Void
    @State private var fullWidth: CGFloat = 0
    @State private var lineWidth: CGFloat = 0

    var body: some View {
        Button(action: onTap) {
            Text(verbatim: " ")
                .font(Typo.entryTitle)
                .hidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { lineWidth = $0 }
                .overlay(alignment: .leading) {
                    Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                        .font(Typo.entryTitle)
                        .foregroundStyle(entry.title.isEmpty ? Palette.muted : Palette.onSurface)
                        .lineLimit(1)
                        .fixedSize()
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { fullWidth = $0 }
                }
                .clipped()
                .mask {
                    HStack(spacing: 0) {
                        Color.black
                        if fullWidth > lineWidth {
                            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing)
                                .frame(width: Dimens.entryTitleFade)
                        }
                    }
                }
                .accessibilityLabel(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct EntryTitle: View {
    let entry: Entry
    let onSave: (String) -> Void
    @Binding var bar: TitleBarActions?
    var autoEdit = false
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var draft = ""
    @State private var cleared: String?
    @State private var selection: TextSelection?
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if editing { editor } else { label }
        }
        .onAppear { if autoEdit { startEditing() } }
    }

    private var label: some View {
        Button(action: startEditing) {
            Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                .font(Typo.entryTitle)
                .foregroundStyle(entry.title.isEmpty ? Palette.muted : Palette.onSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var editor: some View {
        TextField(L.s("list_untitled"), text: $draft, selection: $selection, axis: .vertical)
            .font(Typo.entryTitle)
            .foregroundStyle(Palette.onSurface)
            .submitLabel(.done)
            .autocorrectionDisabled()
            .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)) { note in
                guard let view = note.object as? UITextView else { return }
                view.spellCheckingType = .no
                view.autocorrectionType = .no
                view.inputAssistantItem.leadingBarButtonGroups = []
                view.inputAssistantItem.trailingBarButtonGroups = []
                view.reloadInputViews()
            }
            .focused($focused)
            .onSubmit(finish)
            .onChange(of: draft) { _, value in
                if value.contains("\n") {
                    draft = value.replacingOccurrences(of: "\n", with: "")
                    finish()
                }
            }
            .onChange(of: focused) { _, now in
                if !now { finish() }
            }
            .onAppear {
                selection = TextSelection(insertionPoint: draft.endIndex)
                focused = true
                publishBar()
            }
    }

    private func startEditing() {
        draft = TitleEdit.forEditing(entry.title)
        editing = true
    }

    private func finish() {
        guard editing else { return }
        editing = false
        focused = false
        cleared = nil
        bar = nil
        let title = TitleEdit.clean(draft)
        if title != entry.title { onSave(title) }
    }

    private func copy() {
        let text = TitleEdit.clean(draft)
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        ClipboardMemory.markHandled()
        model.say(L.s("entry_title_copied"), top: true)
    }

    private func remove() {
        cleared = draft
        draft = ""
        focused = true
        publishBar()
    }

    private func restore() {
        guard let previous = cleared else { return }
        draft = previous
        cleared = nil
        focused = true
        publishBar()
    }

    private func publishBar() {
        bar = TitleBarActions(copy: copy, rewrite: remove, restore: cleared == nil ? nil : restore, close: finish)
    }
}
