// Zusammenhang: Paralist/Net/TitleFetcher.swift, Links/TitleExtractor.swift
import Foundation

public enum UrlGuard {
    public static let timeout: TimeInterval = 5
    public static let maxBytes = 512 * 1024
    public static let maxRedirects = 3

    public static func isAllowedUrl(_ url: String) -> Bool {
        guard let c = URLComponents(string: url), let scheme = c.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = c.host?.lowercased(), !host.isEmpty, c.user == nil, c.password == nil else { return false }
        return isAllowedHost(host)
    }

    public static func isAllowedHost(_ host: String) -> Bool {
        let h = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).lowercased()
        if h.isEmpty || h == "localhost" || h.hasSuffix(".localhost") || h.hasSuffix(".local") || h.hasSuffix(".internal") { return false }
        if h == "0.0.0.0" || h == "::" || h == "::1" { return false }
        guard let bytes = literalBytes(h) else { return !h.contains(":") }
        return isPublicAddress(bytes)
    }

    public static func isPublicAddress(_ bytes: [UInt8]) -> Bool {
        if bytes.count == 4 {
            let a = bytes[0], b = bytes[1]
            if a == 0 || a == 127 || a == 10 || a >= 224 { return false }
            if a == 169 && b == 254 { return false }
            if a == 172 && (16...31).contains(b) { return false }
            if a == 192 && b == 168 { return false }
            if a == 100 && (64...127).contains(b) { return false }
            if a == 192 && b == 0 && bytes[2] == 0 { return false }
            if a == 198 && (18...19).contains(b) { return false }
            return true
        }
        guard bytes.count == 16 else { return false }
        if bytes.allSatisfy({ $0 == 0 }) { return false }
        if bytes[0..<15].allSatisfy({ $0 == 0 }) && bytes[15] == 1 { return false }
        if bytes[0..<10].allSatisfy({ $0 == 0 }) && bytes[10] == 0xFF && bytes[11] == 0xFF { return isPublicAddress(Array(bytes[12..<16])) }
        if bytes[0] == 0xFF { return false }
        if bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0x80 { return false }
        if bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0xC0 { return false }
        if bytes[0] == 0xFC || bytes[0] == 0xFD { return false }
        return true
    }

    public static func literalBytes(_ host: String) -> [UInt8]? {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 4, parts.allSatisfy({ !$0.isEmpty && $0.count <= 3 && $0.allSatisfy(\.isNumber) }) {
            let values = parts.compactMap { UInt8($0) }
            return values.count == 4 ? values : nil
        }
        guard host.contains(":") else { return nil }
        return parseIPv6(host)
    }

    private static func parseIPv6(_ text: String) -> [UInt8]? {
        var host = text
        var tail: [UInt8] = []
        if let lastColon = host.lastIndex(of: ":"), host[host.index(after: lastColon)...].contains(".") {
            guard let v4 = literalBytes(String(host[host.index(after: lastColon)...])), v4.count == 4 else { return nil }
            tail = v4
            host = String(host[...lastColon]) + "0:0"
        }
        let halves = host.components(separatedBy: "::")
        guard halves.count <= 2 else { return nil }
        func groups(_ s: String) -> [UInt16]? {
            if s.isEmpty { return [] }
            var out: [UInt16] = []
            for g in s.split(separator: ":", omittingEmptySubsequences: false) {
                guard !g.isEmpty, g.count <= 4, let v = UInt16(g, radix: 16) else { return nil }
                out.append(v)
            }
            return out
        }
        guard let head = groups(halves[0]) else { return nil }
        var all = head
        if halves.count == 2 {
            guard let back = groups(halves[1]), head.count + back.count < 8 else { return nil }
            all += Array(repeating: 0, count: 8 - head.count - back.count) + back
        }
        guard all.count == 8 else { return nil }
        var bytes = all.flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] }
        if !tail.isEmpty { bytes.replaceSubrange(12..<16, with: tail) }
        return bytes
    }
}
