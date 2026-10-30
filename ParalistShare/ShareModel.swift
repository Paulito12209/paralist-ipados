// Zusammenhang: ParalistShare/ShareInbox.swift, ParalistShare/ShareView.swift, Paralist/Files/AttachmentImporter.swift, Paralist/App/AppPaths.swift, Paralist/App/ClipboardMemory.swift, ParalistCore Links/SharedFile.swift, ParalistCore Links/SharedText.swift, ParalistCore Library/PinLimit.swift
import Foundation
import Observation
import ParalistCore

struct SharedItem: Identifiable {
    let id: UUID
    let url: URL
    let name: String
    let size: Int64
    let kind: MediaKind?
    let failure: ImportFailure?
    var title: String
}

@MainActor
@Observable
final class ShareModel {
    var draft = ComposerDraft(type: .note)
    var files: [SharedItem] = []
    var fetching = false
    var ready = false
    var error: String?
    private(set) var entries: [Entry] = []
    let library = EntryLibrary(root: AppPaths.root)
    private let folder = FileManager.default.temporaryDirectory.appendingPathComponent("teilen-\(UUID().uuidString)", isDirectory: true)

    var hasFiles: Bool { !files.isEmpty }
    var usable: [SharedItem] { files.filter { $0.failure == nil } }
    var kinds: Set<MediaKind> { Set(usable.compactMap(\.kind)) }

    func load(_ items: [NSExtensionItem]) async {
        let input = await ShareInbox.read(items, into: folder)
        refresh()
        files = input.files.map(item)
        if files.isEmpty { prepareText(input) } else { draft.type = .file }
        ready = true
        await fetchTitle()
    }

    func refresh() {
        library.rebuild()
        entries = library.all
    }

    var linkPool: [Entry] { draft.linkable(in: hasFiles ? SharedFile.linkCandidates(entries, excluding: kinds) : entries) }

    func create(_ type: EntryType, _ title: String) -> Entry? {
        guard let saved = try? library.save(library.newEntry(type, title: title)) else { return nil }
        refresh()
        return saved
    }

    private func link(_ saved: Entry) {
        let living = Set(library.all.filter { !$0.archived }.map(\.id))
        for id in draft.links.filter(living.contains).sorted() where id != saved.id && !saved.places.contains(id) {
            _ = try? library.setLinked(saved.id, id, linked: true)
        }
    }

    private func item(_ file: ReceivedFile) -> SharedItem {
        let size = Int64((try? file.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let failure: ImportFailure? = file.oversized ? .tooBig : AttachmentImporter.check(file.url)
        var kind: MediaKind?
        if failure == nil, let handle = try? FileHandle(forReadingFrom: file.url) {
            let head = (try? handle.read(upToCount: 4096)) ?? Data()
            try? handle.close()
            kind = FileKind.detectImport(Array(head)).map { MediaKind.of(mime: $0.mime) }
        }
        return SharedItem(id: file.id, url: file.url, name: file.name, size: size, kind: kind, failure: failure, title: SharedFile.title(file.name))
    }

    private func prepareText(_ input: ShareInput) {
        let text = input.text
        var subject = input.subject
        if subject == text { subject = nil }
        let shared = SharedText.parse(String((text ?? "").prefix(8192)), subject: subject.map { String($0.prefix(8192)) })
        var d = ComposerDraft(type: shared.url != nil ? .bookmark : .note)
        d.title = shared.title
        if let url = shared.url {
            d.url = url
            d.confirmUrl()
        }
        if shared.url == nil && d.title.isEmpty { d.title = String((text ?? "").prefix(Limits.maxTitleChars)) }
        draft = d
    }

    func fetchTitle() async {
        guard !hasFiles, draft.type == .bookmark, draft.urlConfirmed else { return }
        let current = draft.title.trimmingCharacters(in: .whitespaces)
        guard current.isEmpty || current.hasPrefix("http") || SharedText.parse(current).url != nil else { return }
        fetching = true
        let title = await TitleFetcher.shared.fetch(draft.url)
        fetching = false
        if let title { draft.title = title }
    }

    func save() -> Bool {
        if hasFiles { return saveFiles() }
        guard let entry = draft.build(library.newEntry(draft.type, title: ""), zone: .current),
              let saved = try? library.save(entry) else { return false }
        library.enforcePinLimit(for: saved, limit: AppPaths.pinLimit)
        link(saved)
        if saved.type == .bookmark { ClipboardMemory.markHandled() }
        return true
    }

    private func saveFiles() -> Bool {
        var done: Set<UUID> = []
        defer { files.removeAll { done.contains($0.id) } }
        for item in usable {
            switch AttachmentImporter.importFile(at: item.url, into: library.store) {
            case .success(let attachment):
                var d = ComposerDraft(type: MediaKind.of(mime: attachment.mime).entryType)
                let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
                d.title = title.isEmpty ? SharedFile.title(attachment.name) : title
                d.places = draft.places
                d.favorite = draft.favorite
                d.pinned = draft.pinned
                d.attachment = attachment
                guard let entry = d.build(library.newEntry(d.type, title: ""), zone: .current),
                      let saved = try? library.save(entry) else {
                    error = L.s("save_failed")
                    return false
                }
                library.enforcePinLimit(for: saved, limit: AppPaths.pinLimit)
                link(saved)
                done.insert(item.id)
            case .failure(let failure):
                error = "\(item.name): \(failure.message)"
                return false
            }
        }
        return true
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: folder)
    }
}
