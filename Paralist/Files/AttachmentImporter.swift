// Zusammenhang: ParalistCore Links/FileKind.swift, ParalistShare/ShareModel.swift, ParalistCore Store/EntryStore.swift (anhaenge/), Composer/ComposerSheet.swift
import CryptoKit
import Foundation
import ImageIO
import ParalistCore
import UIKit

enum ImportFailure: Error {
    case tooBig, notAllowed, unreadable

    var message: String {
        switch self {
        case .tooBig: return L.s("file_too_big")
        case .notAllowed: return L.s("file_type_not_allowed")
        case .unreadable: return L.s("file_unreadable")
        }
    }
}

enum AttachmentImporter {
    static func importFile(at url: URL, into store: EntryStore) -> Result<Attachment, ImportFailure> {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let failure = check(url) { return .failure(failure) }
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return .failure(.unreadable) }
        return importData(data, name: url.lastPathComponent, into: store)
    }

    static func check(_ url: URL) -> ImportFailure? {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if size > FileKind.maxBytes { return .tooBig }
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .unreadable }
        defer { try? handle.close() }
        let head = (try? handle.read(upToCount: 4096)) ?? Data()
        return FileKind.detectImport(Array(head)) == nil ? .notAllowed : nil
    }

    static func importData(_ source: Data, name: String, into store: EntryStore) -> Result<Attachment, ImportFailure> {
        if source.count > FileKind.maxBytes { return .failure(.tooBig) }
        guard var kind = FileKind.detectImport(Array(source.prefix(4096))) else { return .failure(.notAllowed) }
        var data = source
        if kind.isImage {
            guard let encoded = sanitize(source, kind) else { return .failure(.unreadable) }
            data = encoded
            kind = kind == .png ? .png : .jpeg
        }
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let target = store.attachmentsDir.appendingPathComponent(hash)
        if !FileManager.default.fileExists(atPath: target.path) {
            guard (try? data.write(to: target, options: .atomic)) != nil else { return .failure(.unreadable) }
        }
        return .success(Attachment(hash: hash, name: FileKind.sanitizeName(name, kind: kind), mime: kind.mime, size: Int64(data.count)))
    }

    static func sanitize(_ data: Data, _ kind: FileKind) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        let width = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? 0
        let height = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? 0
        let side = min(max(width, height), 4096)
        guard side > 0 else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: side,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        return kind == .png ? image.pngData() : image.jpegData(compressionQuality: 0.9)
    }
}
