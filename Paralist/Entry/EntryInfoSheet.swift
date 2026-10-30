// Zusammenhang: Entry/EntryMetaRow.swift, Entry/EntryTitle.swift, Entry/TitleKeyboardBar.swift, Entry/EntryParts.swift (EntrySheets), Entry/EntryPage.swift (EntrySheet), Entries/TypeLook.swift, Icons/AppIcons.swift, Theme/Dimens.swift (InfoDimens), ParalistCore Library/EntryFacts.swift, Library/Usage.swift
import ParalistCore
import SwiftUI

struct EntryInfoSheet: View {
    let entry: Entry
    var editTitle = false
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var bar: TitleBarActions?
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Palette.outlineVariant).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        EntryTitle(entry: entry, onSave: { title in
                            model.update(entry.id) { var e = $0; e.title = title; return e }
                        }, bar: $bar, autoEdit: editTitle)
                        .id(Self.titleAnchor)
                        .padding(.top, 20)
                        tiles.padding(.top, 20)
                        if let source = EntryFacts.source(entry) {
                            Text(L.s("entry_info_link")).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
                                .padding(.top, InfoDimens.sectionGap)
                                .padding(.bottom, 8)
                            SourceChip(url: source)
                        }
                        Text(L.s(detailsTitle)).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
                            .padding(.top, InfoDimens.sectionGap)
                            .padding(.bottom, 8)
                        ForEach(rows, id: \.label) { row in
                            InfoRow(icon: row.icon, label: L.s(row.label), value: row.value)
                        }
                        if entry.type == .event, !model.usage.changes(entry.id).isEmpty {
                            Text(L.s("entry_info_history")).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
                                .padding(.top, InfoDimens.sectionGap)
                                .padding(.bottom, 8)
                            ForEach(Array(model.usage.changes(entry.id).reversed().enumerated()), id: \.offset) { _, change in
                                InfoRow(icon: change.cancelled ? "xmark.circle" : "arrow.uturn.forward.circle",
                                        label: L.f(change.cancelled ? "entry_info_cancelled_on" : "entry_info_moved_on", L.dateOnly(change.at)),
                                        value: change.cancelled ? "" : change.to.map(L.dateTime) ?? "")
                            }
                        }
                        if entry.type == .deck, model.inDeck(entry.id).isEmpty {
                            Text(L.s("fc_deck_empty")).font(Typo.bodyMedium).foregroundStyle(Palette.muted)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, InfoDimens.edge)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: bar != nil) { _, now in
                    guard now else { return }
                    detent = .large
                    withAnimation(Motion.page) { proxy.scrollTo(Self.titleAnchor, anchor: .top) }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let bar { TitleKeyboardBar(actions: bar) }
        }
        .background(Palette.surfaceContainer)
        .onAppear { if editTitle { detent = .large } }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
    }

    private static let titleAnchor = "title"

    private var header: some View {
        HStack {
            Text(L.s("entry_info_title")).font(Typo.headlineSmall).foregroundStyle(Palette.onSurface)
            Spacer(minLength: 0)
            Button { dismiss() } label: {
                Image(systemName: AppIcons.close).font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.onSurface)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("menu_close"))
        }
        .padding(.leading, InfoDimens.edge)
        .padding(.trailing, InfoDimens.edge - 10)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    private var tiles: some View {
        let tint = TypeLook.of(entry).color.opacity(InfoDimens.tileTint)
        return HStack(spacing: InfoDimens.tileGap) {
            ForEach(tileValues, id: \.label) { tile in
                VStack(spacing: 2) {
                    Text(tile.value).font(Typo.infoValue).foregroundStyle(Palette.onSurface).lineLimit(1).minimumScaleFactor(0.7)
                    Text(L.s(tile.label)).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: InfoDimens.tileHeight)
                .background(tint, in: RoundedRectangle(cornerRadius: InfoDimens.tileRadius, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var tileValues: [(label: String, value: String)] {
        var all = [("entry_info_created", short(entry.created))]
        if EntryFacts.edited(entry) { all.append(("entry_info_updated", short(entry.updated))) }
        let words = EntryFacts.words(entry.body)
        if words > 0 { all.append(("entry_info_words", words.formatted(.number.locale(L.locale)))) }
        return all.map { (label: $0.0, value: $0.1) }
    }

    private var detailsTitle: String {
        "entry_info_details_" + EntryFacts.kind(entry).rawValue
    }

    private var rows: [(icon: String, label: String, value: String)] {
        var all: [(icon: String, label: String, value: String)] = [
            (AppIcons.dateSet, "entry_info_date", L.dateTime(entry.created)),
            (AppIcons.views, "entry_info_views", model.usage.views(entry.id).formatted(.number.locale(L.locale))),
            (AppIcons.shared, "entry_info_shares", model.usage.shares(entry.id).formatted(.number.locale(L.locale))),
        ]
        if entry.type == .deck {
            all.append((AppIcons.flashcards.outlined, "fc_cards_section", model.inDeck(entry.id).count.formatted(.number.locale(L.locale))))
        }
        if entry.type == .event {
            all.append((AppIcons.event, "entry_info_moves", model.usage.moves(entry.id).formatted(.number.locale(L.locale))))
        }
        if let attachment = entry.attachment {
            all.append((AppIcons.fileSize, "entry_info_size", ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file)))
        }
        return all
    }

    private func short(_ date: Date) -> String {
        let sameYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
        let style = sameYear ? Date.FormatStyle.dateTime.day().month(.abbreviated) : Date.FormatStyle.dateTime.day().month(.abbreviated).year()
        return date.formatted(style.locale(L.locale))
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: InfoDimens.rowIcon)).foregroundStyle(Palette.muted).frame(width: 24)
            Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.muted).lineLimit(1)
            Spacer(minLength: 12)
            Text(value).font(Typo.titleMedium).foregroundStyle(Palette.onSurface).lineLimit(1)
        }
        .frame(minHeight: InfoDimens.rowHeight)
        .accessibilityElement(children: .combine)
    }
}

private struct SourceChip: View {
    let url: String
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L.s("entry_info_source")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                Text(url).font(.system(.subheadline, design: .monospaced)).foregroundStyle(Palette.onSurface)
                    .lineLimit(1).truncationMode(.middle)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
            Button(action: copy) {
                Label(L.s("entry_info_copy"), systemImage: AppIcons.copy)
                    .font(Typo.titleSmall)
                    .padding(.horizontal, InfoDimens.copyPad)
                    .frame(height: InfoDimens.copyHeight)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .background(Palette.surfaceHighest, in: Capsule())
        }
        .padding(.leading, InfoDimens.sourcePad)
        .padding(.trailing, InfoDimens.sourcePad - 4)
        .frame(minHeight: InfoDimens.tileHeight)
        .background(Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: InfoDimens.tileRadius, style: .continuous))
    }

    private func copy() {
        UIPasteboard.general.string = url
        ClipboardMemory.markHandled()
        model.say(L.s("entry_info_link_copied"), top: true)
    }
}
