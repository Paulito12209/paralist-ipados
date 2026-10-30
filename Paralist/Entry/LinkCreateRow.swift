// Zusammenhang: Entry/LinkPickerSheet.swift, Entries/TypeLook.swift (ListTitles.new), Icons/AppIcons.swift, ParalistCore Library/LinkPicker.swift (LinkTab.creates), project.yml (ParalistShare)
import ParalistCore
import SwiftUI

struct LinkCreateRow: View {
    let type: EntryType
    let seed: String
    let done: (String) -> Void
    @State private var editing = false
    @State private var name = ""
    @FocusState private var focused: Bool

    private var clean: String { String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Limits.maxTitleChars)) }

    var body: some View {
        HStack(spacing: 16) {
            GlyphIcon(editing ? TypeLook.of(type).icon.outlined : AppIcons.add, size: 20)
                .foregroundStyle(editing ? TypeLook.of(type).color : Palette.primary)
                .frame(width: 28)
            if editing {
                TextField(ListTitles.new(type), text: $name)
                    .font(Typo.bodyLarge)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .onAppear { focused = true }
                Button(action: save) {
                    Image(systemName: AppIcons.confirm)
                        .font(.system(size: 26))
                        .foregroundStyle(clean.isEmpty ? Palette.onSurfaceVariant.opacity(0.4) : Palette.primary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .disabled(clean.isEmpty)
                .accessibilityLabel(L.s("chat_draft_create"))
            } else {
                Button {
                    name = seed.trimmingCharacters(in: .whitespacesAndNewlines)
                    editing = true
                } label: {
                    Text(ListTitles.new(type)).font(Typo.bodyLarge).foregroundStyle(Palette.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(minHeight: 44)
    }

    private func save() {
        guard !clean.isEmpty else { return }
        done(clean)
        name = ""
        editing = false
    }
}
