// Zusammenhang: ParalistShare/ShareModel.swift, ParalistShare/ShareViewController.swift, Paralist/Files/AttachmentImporter.swift, ParalistCore Links/SharedFile.swift
import Foundation
import ParalistCore
import UniformTypeIdentifiers

struct ReceivedFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var oversized = false
}

struct ShareInput {
    var files: [ReceivedFile] = []
    var text: String?
    var subject: String?
}

enum ShareInbox {
    private static let fileTypes: [UTType] = [.image, .movie, .audio, .pdf]

    static func read(_ items: [NSExtensionItem], into folder: URL) async -> ShareInput {
        var input = ShareInput()
        input.subject = items.first?.attributedContentText?.string
        var webText: String?
        for provider in items.flatMap({ $0.attachments ?? [] }) {
            if input.files.count >= SharedFile.maxFiles { break }
            if let type = fileTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) {
                if let file = await copy(provider, type, into: folder) { input.files.append(file) }
                continue
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                guard let url = await link(provider) else { continue }
                if url.isFileURL {
                    if let file = copy(url, name: url.lastPathComponent, into: folder) { input.files.append(file) }
                } else if url.scheme?.hasPrefix("http") == true {
                    webText = url.absoluteString + "\n" + (webText ?? "")
                }
                continue
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                if isFile(provider) {
                    if let file = await copy(provider, .plainText, into: folder) { input.files.append(file) }
                } else if let text = await text(provider) {
                    webText = (webText ?? "") + text
                }
            }
        }
        input.text = webText
        return input
    }

    private static func object<T: Sendable & _ObjectiveCBridgeable>(_ provider: NSItemProvider, _ type: T.Type) async -> T? where T._ObjectiveCType: NSItemProviderReading {
        guard provider.canLoadObject(ofClass: type) else { return nil }
        return await withCheckedContinuation { done in
            _ = provider.loadObject(ofClass: type) { value, _ in done.resume(returning: value) }
        }
    }

    private static func link(_ provider: NSItemProvider) async -> URL? {
        if let url = await object(provider, URL.self) { return url }
        switch await item(provider, UTType.url) {
        case let url as URL: return url
        case let text as String: return URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines))
        case let data as Data: return String(data: data, encoding: .utf8).flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        default: return nil
        }
    }

    private static func text(_ provider: NSItemProvider) async -> String? {
        if let text = await object(provider, String.self) { return text }
        switch await item(provider, UTType.plainText) {
        case let text as String: return text
        case let data as Data: return String(data: data, encoding: .utf8)
        case let url as URL: return url.absoluteString
        default: return nil
        }
    }

    private static func item(_ provider: NSItemProvider, _ type: UTType) async -> NSSecureCoding? {
        await withCheckedContinuation { done in
            provider.loadItem(forTypeIdentifier: type.identifier) { value, _ in done.resume(returning: value) }
        }
    }

    private static func isFile(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
            || !((provider.suggestedName ?? "") as NSString).pathExtension.isEmpty
    }

    private static func copy(_ provider: NSItemProvider, _ type: UTType, into folder: URL) async -> ReceivedFile? {
        let suggested = provider.suggestedName
        return await withCheckedContinuation { done in
            _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
                guard let url else { return done.resume(returning: nil) }
                var name = url.lastPathComponent
                if let suggested, !suggested.isEmpty {
                    name = (suggested as NSString).pathExtension.isEmpty && !url.pathExtension.isEmpty ? suggested + "." + url.pathExtension : suggested
                }
                done.resume(returning: copy(url, name: name, into: folder))
            }
        }
    }

    private static func copy(_ source: URL, name: String, into folder: URL) -> ReceivedFile? {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let dir = folder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let safe = name.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        let target = dir.appendingPathComponent(safe.isEmpty ? "datei" : safe)
        let size = (try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if size > FileKind.maxBytes {
                FileManager.default.createFile(atPath: target.path, contents: nil)
                return ReceivedFile(url: target, name: safe, oversized: true)
            }
            try FileManager.default.copyItem(at: source, to: target)
            return ReceivedFile(url: target, name: safe)
        } catch {
            return nil
        }
    }
}
