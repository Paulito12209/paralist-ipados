// Zusammenhang: ParalistShare/ShareViewController.swift, ParalistShare/ShareModel.swift, ParalistShare/ShareFileViews.swift, Paralist/Entry/LinkPickerSheet.swift, Paralist/Components/Chips.swift, ParalistCore Library/PlacePicker.swift, Paralist/Entry/YouTubePlayer.swift, Paralist/Theme/*, ParalistCore Library/ComposerDraft.swift
import ParalistCore
import SwiftUI

struct ShareView: View {
    @Bindable var model: ShareModel
    let onClose: () -> Void
    @State private var picking = false
    @State private var linking = false

    var body: some View {
        NavigationStack {
            Form {
                if model.ready {
                    if model.hasFiles { fileSections } else { textSections }
                    Section {
                        placeRow
                        linkRow
                        Toggle(isOn: $model.draft.favorite) { Label(L.s("tool_favorite"), systemImage: AppIcons.favorite.outlined) }
                        Toggle(isOn: $model.draft.pinned) { Label(L.s("tool_pin"), systemImage: AppIcons.pin.outlined) }
                    }
                    if let error = model.error {
                        Section { Text(error).font(Typo.bodyMedium).foregroundStyle(Palette.error) }
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.s("dialog_cancel"), action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.s("composer_save")) { if model.save() { onClose() } }
                        .buttonStyle(.glassProminent)
                        .disabled(!model.ready || (model.hasFiles && model.usable.isEmpty))
                }
            }
        }
        .tint(Palette.primary)
    }

    private var placeRow: some View {
        let item = model.draft.target.flatMap { id in model.entries.first { $0.id == id } }.map(ChoiceItem.entry) ?? .noPlace(for: model.draft.type)
        return Button { picking = true } label: {
            pickerLabel(L.s("composer_place_title")) {
                GlyphIcon(item.icon, size: 17).foregroundStyle(model.draft.target == nil ? Palette.onSurfaceVariant : item.tint)
                Text(item.label).lineLimit(1)
            }
        }
        .sheet(isPresented: $picking) {
            let subject = model.draft.linkSubject
            LinkPickerSheet(entry: subject, title: L.s("composer_place_title"), closes: { _ in true },
                            inbox: model.draft.target == nil, excluded: model.draft.pickerExcludes, tabs: PlacePicker.tabs(for: subject.type),
                            pool: PlacePicker.pool(for: subject, in: model.entries),
                            isLinked: { model.draft.isPicked($0) }, create: model.create) { model.draft.pick($0) }
        }
    }

    private var linkRow: some View {
        let count = model.draft.links.count
        return Button { linking = true } label: {
            pickerLabel(L.s("entry_links")) {
                Text(count == 0 ? L.s("share_links_none") : "\(count)")
            }
        }
        .sheet(isPresented: $linking) {
            LinkPickerSheet(entry: model.draft.linkSubject, pool: model.linkPool,
                            isLinked: { model.draft.links.contains($0) }, create: model.create) { other in
                if let other { model.draft.toggleLink(other.id) }
            }
        }
    }

    private func pickerLabel(_ title: String, @ViewBuilder value: () -> some View) -> some View {
        LabeledContent {
            HStack(spacing: 6) {
                value()
                Image(systemName: AppIcons.caret).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Palette.onSurfaceVariant)
        } label: {
            Text(title).foregroundStyle(Palette.onSurface)
        }
    }

    private var title: String {
        guard model.ready else { return "" }
        guard model.hasFiles else { return L.s(model.draft.type == .bookmark ? "share_title_bookmark" : "share_title_note") }
        if model.files.count > 1 { return L.f("share_title_files", model.files.count) }
        switch model.files.first?.kind {
        case .image: return L.s("share_title_image")
        case .video: return L.s("share_title_video")
        case .audio: return L.s("share_title_audio")
        default: return L.s("share_title_document")
        }
    }

    @ViewBuilder
    private var fileSections: some View {
        ForEach($model.files) { $item in
            Section {
                SharePreview(item: item)
                if let failure = item.failure {
                    Text(failure.message).font(Typo.bodyMedium).foregroundStyle(Palette.error)
                } else {
                    let look = TypeLook.of((item.kind ?? .document).entryType)
                    HStack(spacing: 12) {
                        GlyphIcon(look.icon.outlined, size: 17).foregroundStyle(look.color)
                        TextField(L.s(look.hint), text: $item.title, axis: .vertical).font(Typo.titleMedium)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var textSections: some View {
        if let id = VideoLinks.youtubeId(model.draft.url), model.draft.type == .bookmark {
            Section {
                YouTubePlayer(videoId: id)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
            }
        }
        Section {
            HStack(spacing: 12) {
                GlyphIcon(TypeLook.of(model.draft.type).icon.outlined, size: 17).foregroundStyle(TypeLook.of(model.draft.type).color)
                TextField(model.fetching ? L.s("bookmark_fetching") : L.s(TypeLook.of(model.draft.type).hint), text: $model.draft.title, axis: .vertical)
                    .font(Typo.titleMedium)
            }
            if model.draft.type == .bookmark {
                Text(model.draft.url).font(Typo.bodySmall).foregroundStyle(Palette.primary).lineLimit(2)
            }
        }
    }
}
