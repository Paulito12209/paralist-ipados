// Zusammenhang: Paralist/Net/TitleFetcher.swift, Links/UrlGuard.swift
import Foundation

public enum TitleExtractor {
    private static let maxTitle = 300
    private static let og = Pattern("<meta[^>]+property\\s*=\\s*[\"']og:title[\"'][^>]*>", ignoreCase: true)
    private static let ogReversed = Pattern("<meta[^>]+content\\s*=\\s*[\"']([^\"']*)[\"'][^>]+property\\s*=\\s*[\"']og:title[\"'][^>]*>", ignoreCase: true)
    private static let content = Pattern("content\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let title = Pattern("<title[^>]*>(.*?)</title>", ignoreCase: true, dotAll: true)
    private static let tag = Pattern("<[^>]*>")
    private static let entity = Pattern("&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);")
    private static let spaces = Pattern("\\s+")
    private static let jsonTitle = Pattern("\"title\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
    private static let named = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ", "ndash": "–", "mdash": "—", "hellip": "…"]
    private static let oEmbedHosts: Set<String> = ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be"]

    public static func extract(_ html: String) -> String? {
        var raw: String?
        if let m = og.first(in: html), let c = content.first(in: m.value) { raw = c.group(1) }
        if raw == nil, let m = ogReversed.first(in: html) { raw = m.group(1) }
        if raw?.trimmingCharacters(in: .whitespaces).isEmpty ?? true { raw = title.first(in: html)?.group(1) }
        guard let found = raw else { return nil }
        let cleaned = clean(found)
        return cleaned.isEmpty ? nil : cleaned
    }

    public static func oEmbedUrl(_ url: String) -> String? {
        guard let host = URLComponents(string: url)?.host?.lowercased(), oEmbedHosts.contains(host) else { return nil }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.*")
        let encoded = url.addingPercentEncoding(withAllowedCharacters: allowed) ?? url
        return "https://www.youtube.com/oembed?format=json&url=" + encoded
    }

    public static func fromOEmbed(_ json: String) -> String? {
        guard let m = jsonTitle.first(in: json) else { return nil }
        let raw = Array(m.group(1).unicodeScalars)
        var out = String.UnicodeScalarView()
        var i = 0
        while i < raw.count {
            let c = raw[i]
            if c == "\\" && i + 1 < raw.count {
                let n = raw[i + 1]
                if n == "u" {
                    let end = min(i + 6, raw.count)
                    let hex = String(String.UnicodeScalarView(raw[(i + 2)..<end]))
                    if let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) { out.append(scalar) }
                    i += 6
                    continue
                }
                out.append(n == "n" || n == "t" || n == "r" ? " " : n)
                i += 2
            } else {
                out.append(c)
                i += 1
            }
        }
        let cleaned = clean(String(out))
        return cleaned.isEmpty ? nil : cleaned
    }

    public static func clean(_ raw: String) -> String {
        let noTags = tag.replace(raw, with: " ")
        let decoded = entity.replace(noTags) { m -> String in
            let code = m.group(1)
            if code.hasPrefix("#x") { return UInt32(code.dropFirst(2), radix: 16).map(codePoint) ?? "" }
            if code.hasPrefix("#") { return UInt32(code.dropFirst()).map(codePoint) ?? "" }
            return named[code.lowercased()] ?? ""
        }
        let filtered = String(String.UnicodeScalarView(decoded.unicodeScalars.filter { $0.value >= 0x20 || $0 == "\t" }))
        return String(spaces.replace(filtered, with: " ").trimmingCharacters(in: .whitespaces).prefix(maxTitle))
    }

    private static func codePoint(_ value: UInt32) -> String {
        guard (0x20...0x10FFFF).contains(value), !(0xD800...0xDFFF).contains(value), let s = Unicode.Scalar(value) else { return "" }
        return String(s)
    }
}
