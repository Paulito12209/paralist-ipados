// Zusammenhang: ParalistCore Library/ComposerDraft.swift, ParalistCore Library/LinkHistory.swift, ParalistCore Library/LinkPlace.swift, Composer/ComposerParts.swift, Composer/ComposerDateRow.swift, Composer/ComposerDictation.swift, Composer/DictationOverlay.swift, Net/TitleFetcher.swift, Files/AttachmentImporter.swift, Shell/AppSheets.swift, Entry/EntryBlocks.swift (saveCreated), App/ClipboardMemory.swift, Theme/Dimens.swift (ComposerDimens)
import Combine
import ParalistCore
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum ComposerPanel: String, Identifiable {
    case place, deck, type, reminders
    var id: String { rawValue }
}

struct ComposerSheet: View {
    let request: ComposerRequest
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.colorScheme) private var scheme
    @State private var draft = ComposerDraft(type: .note)
    @State private var fetching = false
    @State private var panel: ComposerPanel?
    @State private var importing = false
    @State private var photo: PhotosPickerItem?
    @State private var pickingPhoto = false
    @State private var freshLink = false
    @State private var dictation: ComposerDictation?
    @State private var spokenReminder: Date?
    @State private var dictated = false
    @FocusState private var focus: ComposerField?

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Palette.scrim.opacity(scheme == .dark ? ComposerDimens.dimDark : ComposerDimens.dimLight)
            }
            .ignoresSafeArea()
            .onTapGesture { close() }
            VStack(alignment: .leading, spacing: ComposerDimens.inset) {
                if let dictation {
                    DictationOverlay(dictation: dictation, onDiscard: discardDictation, onApply: finishDictation, onClear: clearDictated, onAgain: restartDictation)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if let attachment = draft.attachment {
                    attachmentTile(attachment)
                        .padding(.leading, ComposerDimens.tileInset)
                }
                card
            }
            .padding(.horizontal, ComposerDimens.edge)
            .padding(.bottom, ComposerDimens.inset)
        }
        .onAppear(perform: setup)
        .onChange(of: dictation?.text) { _, text in
            guard let dictation, let text, dictation.stage == .listening else { return }
            draft = dictation.preview(text)
        }
        .animation(Motion.create, value: dictation == nil)
        .onChange(of: focus) { _, value in
            if value != nil, dictation?.stage == .idle { dictation = nil }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in freshLink = ClipboardMemory.fresh() }
        .task(id: "\(draft.urlConfirmed)-\(draft.type.key)") { await fetchTitle() }
        .sheet(item: $panel) { which in ComposerPanels(which: which, draft: $draft) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.image, .pdf, .audio, .movie, .plainText]) { result in
            if case .success(let url) = result { attach(AttachmentImporter.importFile(at: url, into: model.library.store)) }
        }
        .photosPicker(isPresented: $pickingPhoto, selection: $photo, matching: .any(of: [.images, .videos]))
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    attach(AttachmentImporter.importData(data, name: "bild.jpg", into: model.library.store))
                }
                photo = nil
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                ComposerChipRow(draft: $draft, panel: $panel)
                Spacer(minLength: 0)
                if draft.type == .bookmark && !draft.urlConfirmed {
                    ComposerPasteButton(pulse: freshLink, onPaste: paste)
                }
                Button { close() } label: {
                    Image(systemName: AppIcons.close).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.onSurface)
                        .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(L.s("create_close"))
            }
            .padding([.horizontal, .top], ComposerDimens.inset)
            ComposerFields(draft: $draft, fetching: fetching, focus: $focus, dictating: dictation?.target, dictateBody: { startDictation(.body) })
                .padding(.horizontal, ComposerDimens.textInset)
                .padding(.top, 4)
            if draft.hasDate, draft.date != nil {
                ComposerDateRow(draft: $draft) { panel = .reminders }
                    .padding(.horizontal, ComposerDimens.textInset)
            }
            toolbar
                .padding(ComposerDimens.inset)
        }
        .background(Palette.composerCard, in: RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous)
                .strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1)
        }
    }

    private func attachmentTile(_ attachment: Attachment) -> some View {
        let shape = RoundedRectangle(cornerRadius: ComposerDimens.tileRadius, style: .continuous)
        return ZStack {
            if attachment.mime.hasPrefix("image/"), let url = model.library.store.attachmentFile(attachment.hash),
               let image = Thumbnails.image(url, side: ComposerDimens.tile * 3) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Palette.composerCard
                Image(systemName: AppIcons.file.outlined).font(.system(size: 19)).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .frame(width: ComposerDimens.tile, height: ComposerDimens.tile)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1) }
        .overlay(alignment: .topTrailing) {
            Button { draft.attachment = nil } label: {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.surface)
                    .frame(width: ComposerDimens.tileClose, height: ComposerDimens.tileClose)
                    .background(Palette.onSurface.opacity(0.8), in: Circle())
                    .overlay { Circle().strokeBorder(Palette.surface.opacity(0.6), lineWidth: 1) }
                    .padding(ComposerDimens.tileCloseInset)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("file_remove"))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(attachment.name)
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            Menu {
                Button { importing = true } label: { Label(L.s("file_choose"), systemImage: AppIcons.file.outlined) }
                Button { pickingPhoto = true } label: { Label(L.s("page_media"), systemImage: AppIcons.image) }
            } label: {
                Image(systemName: AppIcons.add).font(.system(size: 17, weight: .medium))
                    .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                    .background(Palette.composerButton, in: Circle())
                    .foregroundStyle(Palette.onSurface)
            }
            .accessibilityLabel(L.s("tool_attach"))
            .padding(.trailing, 4)
            if draft.type != .flashcard {
                toolButton(AppIcons.text, on: draft.showBody, label: "tool_text") {
                    draft.showBody.toggle()
                    if draft.showBody { focus = .body }
                }
            }
            if draft.hasDate {
                toolButton(AppIcons.event, on: draft.date != nil, label: "composer_date") {
                    if draft.date == nil { draft.openDate(now: Date(), zone: .current) } else { draft.clearDate() }
                }
            } else {
                toolButton(draft.reminders.isEmpty ? AppIcons.bell.outlined : AppIcons.bell.filled, on: !draft.reminders.isEmpty, label: "reminder_bell") { panel = .reminders }
            }
            toolButton(draft.favorite ? AppIcons.favorite.filled : AppIcons.favorite.outlined, on: draft.favorite, tint: Palette.fixed(0xF59E0B), label: "tool_favorite") { draft.favorite.toggle() }
            Spacer(minLength: 24)
            if draft.hasPlace { placePicker }
            actionButton
        }
    }

    private var placePicker: some View {
        let item = draft.target.flatMap { model.entry($0) }.map(ChoiceItem.entry) ?? .noPlace(for: draft.type)
        return Button { panel = .place } label: {
            HStack(spacing: 6) {
                GlyphIcon(item.icon, size: 16)
                    .foregroundStyle(draft.target == nil ? Palette.onSurface : item.tint)
                Text(item.label)
                    .font(Typo.labelLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                Image(systemName: AppIcons.caret).font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
            }
            .padding(.horizontal, 12)
            .frame(height: ComposerDimens.button)
            .background(Palette.composerButton, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
        .accessibilityLabel(L.s("composer_place_title"))
    }

    private var canSave: Bool {
        if draft.type == .bookmark { return !draft.url.trimmingCharacters(in: .whitespaces).isEmpty }
        return !draft.title.trimmingCharacters(in: .whitespaces).isEmpty || draft.attachment != nil
    }

    private var dictates: Bool { !canSave }

    private var actionButton: some View {
        Button { dictates ? startDictation(.auto) : save() } label: {
            Image(systemName: dictates ? AppIcons.audio : AppIcons.send)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(dictates ? Palette.onSurface : Palette.onPrimary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                .background(dictates ? Palette.composerButton : Palette.primary, in: Circle())
                .opacity(dictates || canSave ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!dictates && !canSave)
        .animation(Motion.short, value: dictates)
        .accessibilityLabel(L.s(dictates ? "dictation_title" : "composer_save"))
    }

    private func toolButton(_ icon: String, on: Bool, tint: Color = Palette.primary, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 19)).foregroundStyle(on ? tint : Palette.onSurfaceVariant)
                .frame(width: ComposerDimens.tool, height: ComposerDimens.button)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(label))
    }

    private func setup() {
        var d = ComposerDraft(type: request.type)
        d.date = request.day
        d.minute = request.hour.map { $0 * 60 }
        if let title = request.title { d.title = title }
        if let place = request.place { d.places = [place] }
        if let link = request.link {
            if let partner = model.entry(link) { d.linkTo(partner) } else { d.link = link }
        }
        if let url = request.url {
            d.url = url
            d.confirmUrl()
        }
        draft = d
        freshLink = ClipboardMemory.fresh()
        focus = d.type == .bookmark && !d.urlConfirmed ? .url : .title
    }

    private func startDictation(_ target: ComposerDictation.Target) {
        guard dictation == nil else { return }
        focus = nil
        let session = ComposerDictation(base: draft, periods: model.prefs.periods, target: target)
        dictation = session
        dictated = true
        Task { await session.start() }
    }

    private func discardDictation() {
        guard let dictation else { return }
        if dictation.stage == .listening, dictation.text.isEmpty {
            dictation.cancel()
            draft = dictation.base
            self.dictation = nil
            return
        }
        dictation.discard()
    }

    private func clearDictated() {
        guard let dictation else { return }
        if dictation.intoBody { draft.body = dictation.base.body } else { draft.title = "" }
        self.dictation = nil
    }

    private func restartDictation() {
        guard let old = dictation else { return }
        let session = ComposerDictation(base: draft, periods: model.prefs.periods, target: old.target)
        dictation = session
        Task { await session.start() }
    }

    private func finishDictation() {
        guard let dictation, dictation.stage == .listening else { return }
        Task {
            let (result, reminder) = await dictation.finish()
            draft = result
            if let reminder { spokenReminder = reminder }
            if self.dictation === dictation { self.dictation = nil }
        }
    }

    private func fetchTitle() async {
        guard draft.type == .bookmark, draft.urlConfirmed, draft.title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        fetching = true
        let url = draft.url
        let title = await TitleFetcher.shared.fetch(url)
        fetching = false
        if let title, draft.url == url, draft.title.trimmingCharacters(in: .whitespaces).isEmpty { draft.title = title }
    }

    private func attach(_ result: Result<Attachment, ImportFailure>) {
        switch result {
        case .success(let attachment):
            draft.attach(attachment)
            model.say(L.f("file_attached", attachment.name))
        case .failure(let failure):
            model.say(failure.message)
        }
    }

    private func save() {
        if draft.type == .bookmark && !draft.urlConfirmed {
            draft.confirmUrl()
            if draft.urlConfirmed { focus = .title }
            return
        }
        var reminderAt = draft.absorbTitle(now: Date(), zone: .current, periods: model.prefs.periods)
        if reminderAt == nil, let spoken = spokenReminder, draft.reminders.contains(spoken) { reminderAt = spoken }
        if reminderAt == nil, draft.type != .event, spokenReminder != nil || dictated { reminderAt = draft.reminders.min() }
        guard let built = draft.build(model.newEntry(draft.type), zone: .current) else { return }
        let entry = AttachmentEntry.owner(built)
        guard let saved = model.saveCreated(entry) else {
            model.say(L.s("save_failed"))
            return
        }
        if model.saveAttachmentEntry(draft.attachment, for: saved) { model.say(L.s("attachment_entry_saved")) }
        if entry.type == .bookmark { ClipboardMemory.markHandled() }
        if !entry.reminders.isEmpty || entry.due != nil {
            Task { _ = await model.reminders.ensurePermission() }
        }
        close()
        if let reminderAt { model.cheer(L.s("reminder_set_title"), L.f("reminder_set_body", L.dateTime(reminderAt))) }
    }

    private func paste(_ link: String) {
        ClipboardMemory.markHandled()
        freshLink = false
        if let saved = LinkHistory.saved(link, in: model.all) {
            close()
            router.open(.entry(saved.id))
            model.say(L.s("bookmark_exists"))
            return
        }
        if model.links.knows(link) { model.say(L.s("bookmark_known")) }
        draft.paste(link)
        if draft.urlConfirmed { focus = .title }
    }

    private func close() {
        dictation?.cancel()
        dictation = nil
        if freshLink && draft.type == .bookmark { ClipboardMemory.markHandled() }
        focus = nil
        router.composer = nil
    }
}
