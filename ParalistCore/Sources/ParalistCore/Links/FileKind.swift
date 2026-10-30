// Zusammenhang: Paralist/Files/AttachmentImporter.swift, Model/Entry.swift (Attachment)
import Foundation

public enum FileKind: String, CaseIterable, Sendable {
    case jpeg, png, gif, webp, pdf, mp3, mp4, m4a, text

    public static let maxBytes = 50 * 1024 * 1024
    private static let active = ["<!doctype", "<html", "<script", "<?xml", "<svg", "#!", "<?php", "<body", "<iframe"]
    private static let textExtensions = ["md", "markdown"]
    private static let heifBrands = ["heic", "heix", "hevc", "hevx", "heim", "heis", "mif1", "msf1", "avif"]

    public var mime: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .gif: return "image/gif"
        case .webp: return "image/webp"
        case .pdf: return "application/pdf"
        case .mp3: return "audio/mpeg"
        case .mp4: return "video/mp4"
        case .m4a: return "audio/mp4"
        case .text: return "text/plain"
        }
    }

    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .text: return "txt"
        default: return rawValue
        }
    }

    public var isImage: Bool { [.jpeg, .png, .gif, .webp].contains(self) }

    public static func detectSafe(_ head: [UInt8]) -> FileKind? {
        guard let kind = detect(head) else { return nil }
        if kind != .text { return kind }
        let start = String(decoding: head.prefix(512), as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF} \n\r\t")).lowercased()
        return active.contains { start.hasPrefix($0) } ? nil : kind
    }

    public static func isHeif(_ head: [UInt8]) -> Bool {
        guard head.count >= 12, Array(head[4..<8]) == Array("ftyp".utf8) else { return false }
        let brand = String(decoding: head[8..<12], as: UTF8.self)
        return heifBrands.contains(brand)
    }

    public static func detectImport(_ head: [UInt8]) -> FileKind? {
        isHeif(head) ? .jpeg : detectSafe(head)
    }

    public static func detect(_ head: [UInt8]) -> FileKind? {
        func at(_ i: Int) -> Int { i < head.count ? Int(head[i]) : -1 }
        func ascii(_ offset: Int, _ text: String) -> Bool {
            text.unicodeScalars.enumerated().allSatisfy { at(offset + $0.offset) == Int($0.element.value) }
        }
        if at(0) == 0xFF && at(1) == 0xD8 && at(2) == 0xFF { return .jpeg }
        if ascii(0, "\u{89}PNG\r\n\u{1A}\n") { return .png }
        if ascii(0, "GIF87a") || ascii(0, "GIF89a") { return .gif }
        if ascii(0, "RIFF") && ascii(8, "WEBP") { return .webp }
        if ascii(0, "%PDF-") { return .pdf }
        if ascii(0, "ID3") || (at(0) == 0xFF && at(1) >= 0 && (at(1) & 0xE6) == 0xE2) { return .mp3 }
        if isHeif(head) { return nil }
        if ascii(4, "ftyp") { return ascii(8, "M4A ") || ascii(8, "M4B ") ? .m4a : .mp4 }
        return looksLikeText(head) ? .text : nil
    }

    private static func looksLikeText(_ head: [UInt8]) -> Bool {
        if head.isEmpty || head.contains(0) { return false }
        var sample = Array(head.prefix(4096))
        var back = 0
        while back < 3, let last = sample.last, last & 0xC0 == 0x80 {
            sample.removeLast()
            back += 1
        }
        if let last = sample.last, last & 0xC0 == 0xC0 { sample.removeLast() }
        return String(validatingUTF8CString: sample) != nil
    }

    public static func sanitizeName(_ name: String, kind: FileKind) -> String {
        let last = name.split(separator: "/").last.map(String.init) ?? name
        let base = (last.split(separator: "\\").last.map(String.init) ?? last)
        let stripped = String(String.UnicodeScalarView(base.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }))
        let trimmed = String(stripped.trimmingCharacters(in: .whitespaces).prefix(120))
        var stem = trimmed
        if let dot = trimmed.lastIndex(of: ".") { stem = String(trimmed[..<dot]) }
        if stem.trimmingCharacters(in: .whitespaces).isEmpty { stem = "datei" }
        var ext = kind.fileExtension
        if kind == .text, let dot = trimmed.lastIndex(of: ".") {
            let original = trimmed[trimmed.index(after: dot)...].lowercased()
            if textExtensions.contains(original) { ext = original }
        }
        return "\(stem).\(ext)"
    }
}

private extension String {
    init?(validatingUTF8CString bytes: [UInt8]) {
        var iterator = bytes.makeIterator()
        var decoder = UTF8()
        var out = String.UnicodeScalarView()
        loop: while true {
            switch decoder.decode(&iterator) {
            case .scalarValue(let s): out.append(s)
            case .emptyInput: break loop
            case .error: return nil
            }
        }
        self = String(out)
    }
}
