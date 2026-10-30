// Zusammenhang: Entry/EntryPage.swift, Entry/EntryActions.swift (EntryTextToggle), Entry/EntryCanvasPanel.swift, Entry/EntryBlocks.swift (EntryTextBox, Bearbeiten im Container), Entry/TitleKeyboardBar.swift (BodyKeyboardBar), Entry/EntryParts.swift (TextEditorSheet), Theme/CanvasOpenDimens.swift (entryTextViewMin), App/AppModel.swift, ParalistCore Text/TextEdits.swift, docs/detailseite.md
import ParalistCore
import SwiftUI

struct EntryBodyEditor: View {
    let entry: Entry
    let autofocus: Bool
    var inCard = false
    var minHeight: CGFloat = Dimens.entryTextViewMin
    @Binding var bar: BodyBarActions?
    @Binding var caretBottom: CGFloat
    var onRemoved: () -> Void = {}
    var onEnd: () -> Void = {}
    @Environment(AppModel.self) private var model
    @State private var draft = ""
    @State private var selection: TextSelection?
    @State private var history = EditHistory()
    @State private var restoring = false
    @State private var confirmRemove = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            field
            if !inCard, !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EntryTextToggle(label: L.s("entry_body_remove"), isOn: Binding(get: { true }, set: { on in if !on { confirmRemove = true } }))
            }
        }
        .confirmationDialog(L.s("entry_body_remove_question"), isPresented: $confirmRemove, titleVisibility: .visible) {
            Button(L.s("entry_body_remove"), role: .destructive, action: remove)
        } message: {
            Text(L.s("entry_body_remove_message"))
        }
    }

    private var insets: EdgeInsets {
        let pad = Dimens.canvasCardPad
        return inCard ? EdgeInsets(top: 0, leading: pad, bottom: pad, trailing: pad) : EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }

    private var field: some View {
        TextField(L.s("entry_body_hint"), text: $draft, selection: $selection, axis: .vertical)
            .font(Typo.bodyLarge)
            .foregroundStyle(Palette.onSurface)
            .lineLimit((inCard ? 1 : 6)...)
            .focused($focused)
            .padding(insets)
            .background(alignment: .topLeading) {
                Text(String(draft.prefix(cursor)) + " ")
                    .font(Typo.bodyLarge)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .id(Self.caretAnchor)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).maxY } action: { caretBottom = $0 }
                    .padding(insets)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: minHeight)
            .background(inCard ? Color.clear : Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: Dimens.listRadius))
            .contentShape(RoundedRectangle(cornerRadius: Dimens.listRadius))
            .onTapGesture { focused = true }
            .padding(.horizontal, inCard ? 0 : Dimens.entryInset)
            .onAppear {
                restoring = !entry.body.isEmpty
                draft = entry.body
                selection = TextSelection(insertionPoint: draft.endIndex)
                focused = autofocus
            }
            .onChange(of: autofocus) { _, now in if now { focused = true } }
            .onChange(of: entry.body) { _, now in
                guard !focused, now != draft else { return }
                restoring = true
                draft = now
                selection = TextSelection(insertionPoint: draft.endIndex)
            }
            .onChange(of: draft) { old, new in
                if restoring { restoring = false } else { history.record(from: old, to: new) }
                publish()
            }
            .onChange(of: focused) { _, now in
                if now {
                    publish()
                } else {
                    bar = nil
                    save()
                    onEnd()
                }
            }
            .onDisappear {
                bar = nil
                save()
            }
    }

    static let caretAnchor = "bodyCaret"

    private func publish() {
        guard focused else { return }
        bar = BodyBarActions(undo: history.canUndo ? undo : nil, deleteWord: deleteWord, close: { focused = false })
    }

    private var cursor: Int {
        guard let selection, case .selection(let range) = selection.indices else { return draft.count }
        let units = min(max(range.lowerBound.utf16Offset(in: draft), 0), draft.utf16.count)
        return String(draft.utf16.prefix(units))?.count ?? draft.count
    }

    private func deleteWord() {
        let result = TextEdits.deleteWord(draft, before: cursor)
        guard result.text != draft else { return }
        draft = result.text
        selection = TextSelection(insertionPoint: draft.index(draft.startIndex, offsetBy: result.offset))
    }

    private func remove() {
        focused = false
        restoring = true
        draft = ""
        save()
        onRemoved()
    }

    private func undo() {
        guard let previous = history.undo() else { return }
        restoring = true
        draft = previous
        selection = TextSelection(insertionPoint: draft.endIndex)
    }

    private func save() {
        let trimmed = draft.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let body = trimmed.isEmpty ? "" : trimmed + "\n"
        guard body != entry.body else { return }
        model.update(entry.id) { var e = $0; e.body = body; return e }
    }
}
