// Zusammenhang: Composer/ComposerSheet.swift, Components/Chips.swift, Entry/ReminderSheet.swift, Entry/LinkPickerSheet.swift, ParalistCore Library/PlacePicker.swift, Theme/Dimens.swift (ComposerDimens, TaskDimens Puls), ParalistCore Links/SharedText.swift
import ParalistCore
import SwiftUI
import UniformTypeIdentifiers

enum ComposerField: Hashable { case url, title, body }

struct ComposerChipRow: View {
    @Binding var draft: ComposerDraft
    @Binding var panel: ComposerPanel?
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let look = TypeLook.of(draft.type)
                Button { panel = .type } label: {
                    ComposerChip(icon: look.icon.outlined, label: L.s(look.label), tint: look.color, selected: true, pill: true)
                }
                .accessibilityLabel(L.s("composer_type"))
                if draft.type == .flashcard {
                    let deck = draft.deck.flatMap { model.entry($0) }
                    Button { panel = .deck } label: {
                        ComposerChip(icon: AppIcons.deck.outlined, label: deck?.title ?? L.s("composer_deck"), selected: deck != nil, pill: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ComposerPasteButton: View {
    let pulse: Bool
    let onPaste: (String) -> Void
    @State private var waving = false

    var body: some View {
        PasteButton(supportedContentTypes: [.url, .plainText]) { providers in
            Self.link(in: providers) { link in Task { @MainActor in onPaste(link) } }
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .overlay {
            if pulse {
                Circle().stroke(Palette.primary, lineWidth: 2)
                    .scaleEffect(waving ? TaskDimens.pulseScale : 1)
                    .opacity(waving ? 0 : 0.9)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: TaskDimens.pulseSeconds).repeatForever(autoreverses: false)) { waving = true } }
    }

    private static func link(in providers: [NSItemProvider], found: @escaping @Sendable (String) -> Void) {
        guard let provider = providers.first else { return }
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { found(url.absoluteString) }
            }
        } else if provider.canLoadObject(ofClass: String.self) {
            _ = provider.loadObject(ofClass: String.self) { text, _ in
                guard let text else { return }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { found(SharedText.parse(trimmed).url ?? trimmed) }
            }
        }
    }
}

struct ComposerFields: View {
    @Binding var draft: ComposerDraft
    let fetching: Bool
    var focus: FocusState<ComposerField?>.Binding
    var dictating: ComposerDictation.Target?
    var dictateBody: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if draft.type == .bookmark && !draft.urlConfirmed {
                TextField(L.s("bookmark_link_hint"), text: $draft.url)
                    .font(Typo.dm(18, .medium))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused(focus, equals: .url)
                    .onSubmit {
                        draft.confirmUrl()
                        if draft.urlConfirmed { focus.wrappedValue = .title }
                    }
                    .frame(minHeight: ComposerDimens.control)
                if draft.urlError {
                    Text(L.s("composer_url_error")).font(Typo.bodySmall).foregroundStyle(Palette.error)
                }
            } else {
                TextField(fetching ? L.s("bookmark_fetching") : L.s(TypeLook.of(draft.type).hint), text: $draft.title, axis: .vertical)
                        .font(Typo.dm(18, .medium))
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                        .focused(focus, equals: .title)
                        .frame(minHeight: ComposerDimens.control, alignment: .leading)
                        .onChange(of: draft.title) { _, value in
                            if value.contains("\n") {
                                draft.title = value.replacingOccurrences(of: "\n", with: " ")
                                focus.wrappedValue = draft.showsBody ? .body : nil
                            }
                            if draft.title.count > Limits.maxInputTitleChars { draft.title = String(draft.title.prefix(Limits.maxInputTitleChars)) }
                        }
                if draft.title.count >= Limits.maxInputTitleChars - ComposerDimens.counterTail {
                    Text(L.f("composer_title_count", draft.title.count, Limits.maxInputTitleChars))
                        .font(Typo.bodySmall).foregroundStyle(draft.title.count >= Limits.maxInputTitleChars ? Palette.error : Palette.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if draft.type == .bookmark {
                    Button { draft.urlConfirmed = false } label: {
                        Text(draft.url).font(Typo.bodySmall).foregroundStyle(Palette.primary).lineLimit(1).truncationMode(.middle)
                    }
                    .buttonStyle(.plain)
                }
                if draft.showsBody {
                    HStack(alignment: .top, spacing: ComposerDimens.inset) {
                        TextField(draft.type == .flashcard ? L.s("composer_back_hint") : L.s("composer_body_hint"), text: $draft.body, axis: .vertical)
                            .font(Typo.bodyLarge)
                            .lineLimit(1...8)
                            .focused(focus, equals: .body)
                        micButton(dictating == .body, action: dictateBody)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func micButton(_ on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: AppIcons.audio).font(.system(size: 17))
                .foregroundStyle(on ? Palette.primary : Palette.onSurfaceVariant)
                .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s("dictation_title"))
    }
}

struct ComposerPanels: View {
    let which: ComposerPanel
    @Binding var draft: ComposerDraft
    @Environment(AppModel.self) private var model

    var body: some View {
        switch which {
        case .place:
            LinkPickerSheet(entry: draft.linkSubject, title: L.s("composer_place_title"), closes: { _ in true },
                            inbox: draft.target == nil, excluded: draft.pickerExcludes, tabs: PlacePicker.tabs(for: draft.type),
                            pool: PlacePicker.pool(for: draft.linkSubject, in: model.all),
                            isLinked: { draft.isPicked($0) },
                            create: { model.save(model.newEntry($0, title: $1)) }) { other in draft.pick(other) }
        case .deck:
            ChoiceSheet(title: L.s("composer_deck"), items: model.byType(.deck).map(ChoiceItem.entry),
                        selected: Set(draft.deck.map { [$0] } ?? []), emptyText: L.s("composer_deck_none")) { id in
                draft.chooseDeck(id)
            }
        case .type:
            ChoiceSheet(title: L.s("composer_type"), items: EntryType.allCases.map(ChoiceItem.type), selected: [draft.type.key]) { key in
                if let type = EntryType.fromKey(key) { draft.type = type }
            }
        case .reminders:
            ReminderSheet(reminders: $draft.reminders, eventStart: draft.start(zone: .current), offset: $draft.eventOffset)
        }
    }
}
