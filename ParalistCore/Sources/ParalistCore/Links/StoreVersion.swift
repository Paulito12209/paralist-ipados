// Zusammenhang: Paralist/Net/UpdateChecker.swift, Paralist/App/StoreLinks.swift, Tests/StoreVersionTests.swift
import Foundation

public enum StoreVersion {
    public static func fromLookup(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = root["results"] as? [[String: Any]],
              let version = results.first?["version"] as? String else { return nil }
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public static func isNewer(_ store: String, than installed: String) -> Bool {
        let a = parts(store)
        let b = parts(installed)
        guard !a.isEmpty, !b.isEmpty else { return false }
        let n = max(a.count, b.count)
        for i in 0..<n {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private static func parts(_ s: String) -> [Int] {
        let pieces = s.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".", omittingEmptySubsequences: false)
        var out: [Int] = []
        for piece in pieces {
            guard let n = Int(piece) else { return [] }
            out.append(n)
        }
        return out
    }
}
