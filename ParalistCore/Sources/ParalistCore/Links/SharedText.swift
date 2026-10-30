// Zusammenhang: Links/IncomingLink.swift, Paralist/App/ParalistApp.swift, ParalistShare/ShareView.swift, Markdown/Limits.swift
import Foundation

public struct SharedText: Hashable, Sendable {
    public let url: String?
    public let title: String

    public init(url: String?, title: String) {
        self.url = url
        self.title = title
    }

    private static let urlPattern = Pattern("https?://[^\\s<>\"']+")

    public static func parse(_ text: String?, subject: String? = nil) -> SharedText {
        let body = String((text ?? "").prefix(Limits.maxUrlChars * 4))
        let match = urlPattern.first(in: body)
        var url: String?
        if let m = match {
            var value = m.value
            while let last = value.last, ".,);".contains(last) { value.removeLast() }
            if value.count <= Limits.maxUrlChars { url = value }
        }
        var rest = body
        if let m = match { rest.removeSubrange(m.range) }
        let firstLine = rest.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? ""
        let cleanSubject = subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String
        if let s = cleanSubject, !s.isEmpty, !urlPattern.matches(s) { title = s } else { title = firstLine }
        return SharedText(url: url, title: String(title.prefix(Limits.maxTitleChars)))
    }
}
