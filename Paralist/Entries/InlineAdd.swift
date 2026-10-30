// Zusammenhang: Entries/EntryRow.swift (QuickAddRow, RowMetrics), Entries/ListAdd.swift, Pages/OverviewPage.swift, Pages/ListPage.swift, Pages/TasksPage.swift, ParalistCore Library/ComposerDraft.swift
import ParalistCore
import SwiftUI

enum InlineAdd {
    static let anchor = "inlineAdd"

    static func supports(_ type: EntryType) -> Bool {
        [.note, .task, .project, .area, .document, .tag].contains(type)
    }

    static func type(of addition: ListAdd) -> EntryType? {
        if case .compose(let type) = addition, supports(type) { return type }
        return nil
    }

    static func hint(_ type: EntryType) -> String {
        switch type {
        case .task: return L.s("composer_hint_task")
        case .project: return L.s("composer_hint_project")
        case .area: return L.s("composer_hint_area")
        case .document: return L.s("composer_hint_document")
        case .tag: return L.s("composer_hint_tag")
        default: return L.s("composer_hint_note")
        }
    }

    @MainActor
    static func save(_ type: EntryType, title: String, root: Entry? = nil, model: AppModel) {
        var draft = ComposerDraft(type: type)
        draft.title = title
        if let root {
            if EntryParent.canHold(root, for: type) { draft.places = [root.id] } else { draft.linkTo(root) }
        }
        guard let built = draft.build(model.newEntry(type), zone: .current) else { return }
        _ = model.saveCreated(built)
    }
}

struct InlineAddRow: View {
    let type: EntryType
    let label: String
    @Binding var editing: Bool
    var metrics = RowMetrics()
    let onAdd: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        if editing {
            HStack(spacing: metrics.gap) {
                glyph.frame(width: metrics.glyph, height: metrics.glyph)
                TextField(text: $text, prompt: Text(InlineAdd.hint(type)).foregroundStyle(Palette.addPlaceholder)) { EmptyView() }
                    .font(Typo.bodyLarge)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(submit)
                    .onChange(of: text) { _, value in
                        if value.contains("\n") { text = value.replacingOccurrences(of: "\n", with: " ") }
                        if text.count > Limits.maxTitleChars { text = String(text.prefix(Limits.maxTitleChars)) }
                    }
            }
            .padding(.leading, metrics.inset)
            .padding(.trailing, 16)
            .frame(minHeight: metrics.minHeight)
            .onAppear { focused = true }
            .onChange(of: focused) { _, now in
                if !now {
                    let value = text.trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty { onAdd(value) }
                    text = ""
                    editing = false
                }
            }
        } else {
            QuickAddRow(label: label, metrics: metrics) { editing = true }
        }
    }

    @ViewBuilder
    private var glyph: some View {
        if type == .task {
            Image(systemName: AppIcons.circle).font(.system(size: 22)).foregroundStyle(Palette.openTask)
        } else {
            GlyphIcon(AppIcons.addCircle, size: metrics.icon).foregroundStyle(Palette.addPlaceholder)
        }
    }

    private func submit() {
        let value = text.trimmingCharacters(in: .whitespaces)
        if value.isEmpty {
            editing = false
            return
        }
        onAdd(value)
        text = ""
        focused = true
    }
}

extension View {
    func inlineAddLift(_ editing: Bool, id: String = InlineAdd.anchor, rows: Int, proxy: ScrollViewProxy) -> some View {
        modifier(InlineAddLift(editing: editing, id: id, rows: rows, proxy: proxy))
    }
}

private struct InlineAddLift: ViewModifier {
    let editing: Bool
    let id: String
    let rows: Int
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in lift() }
            .onChange(of: rows) { _, _ in
                guard editing else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    lift()
                }
            }
    }

    private func lift() {
        guard editing else { return }
        withAnimation(Motion.short) { proxy.scrollTo(id, anchor: .bottom) }
    }
}
