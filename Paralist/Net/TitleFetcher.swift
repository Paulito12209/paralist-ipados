// Zusammenhang: Net/UpdateChecker.swift, ParalistCore Links/UrlGuard.swift, Net/LinkColors.swift, Net/LinkIcons.swift, ParalistCore Links/TitleExtractor.swift, Composer/ComposerSheet.swift, ParalistShare/ShareView.swift
import Foundation
import ParalistCore

final class TitleFetcher: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static let shared = TitleFetcher()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = UrlGuard.timeout
        config.timeoutIntervalForResource = UrlGuard.timeout * 2
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func fetch(_ url: String) async -> String? {
        if let oembed = TitleExtractor.oEmbedUrl(url), let json = await load(oembed, accept: "application/json"),
           let title = TitleExtractor.fromOEmbed(json) {
            return title
        }
        guard let html = await load(url, accept: "text/html") else { return nil }
        return TitleExtractor.extract(html)
    }

    func html(_ url: String) async -> String? {
        await load(url, accept: "text/html")
    }

    func json(_ url: String) async -> String? {
        await load(url, accept: "application/json")
    }

    func image(_ url: String) async -> Data? {
        await bytes(url, accept: "image/*")
    }

    private func load(_ start: String, accept: String) async -> String? {
        guard let data = await bytes(start, accept: accept) else { return nil }
        return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    }

    private func bytes(_ start: String, accept: String) async -> Data? {
        var current = start
        for _ in 0...UrlGuard.maxRedirects {
            guard UrlGuard.isAllowedUrl(current), let target = URL(string: current), await Self.resolvesPublic(target.host ?? "") else { return nil }
            var request = URLRequest(url: target)
            request.setValue(accept == "text/html" ? "text/html,application/xhtml+xml" : accept, forHTTPHeaderField: "Accept")
            request.setValue("de, en;q=0.8", forHTTPHeaderField: "Accept-Language")
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Paralist", forHTTPHeaderField: "User-Agent")
            guard let result = try? await session.bytes(for: request), let http = result.1 as? HTTPURLResponse else { return nil }
            let bytes = result.0
            if (300...399).contains(http.statusCode) {
                guard let location = http.value(forHTTPHeaderField: "Location"), let next = URL(string: location, relativeTo: target) else { return nil }
                current = next.absoluteString
                continue
            }
            guard (200...299).contains(http.statusCode) else { return nil }
            let type = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
            let ok: Bool
            switch accept {
            case "application/json": ok = type.contains("json")
            case "image/*": ok = type.hasPrefix("image/") || type.contains("octet-stream") || type.contains("icon")
            default: ok = type.contains("text/html") || type.contains("application/xhtml")
            }
            guard ok else { return nil }
            var data = Data()
            do {
                for try await byte in bytes {
                    data.append(byte)
                    if data.count >= UrlGuard.maxBytes { break }
                }
            } catch {
                return nil
            }
            return data
        }
        return nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        nil
    }

    static func resolvesPublic(_ host: String) async -> Bool {
        if UrlGuard.literalBytes(host) != nil { return UrlGuard.isAllowedHost(host) }
        return await Task.detached {
            var hints = addrinfo(ai_flags: 0, ai_family: AF_UNSPEC, ai_socktype: SOCK_STREAM, ai_protocol: 0, ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil)
            var result: UnsafeMutablePointer<addrinfo>?
            guard getaddrinfo(host, nil, &hints, &result) == 0, let first = result else { return false }
            defer { freeaddrinfo(first) }
            var node: UnsafeMutablePointer<addrinfo>? = first
            var any = false
            while let info = node {
                let addr = info.pointee.ai_addr
                if info.pointee.ai_family == AF_INET, let addr {
                    let raw = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
                    let bytes = withUnsafeBytes(of: raw) { Array($0) }
                    if !UrlGuard.isPublicAddress(bytes) { return false }
                    any = true
                } else if info.pointee.ai_family == AF_INET6, let addr {
                    let raw = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee.sin6_addr }
                    let bytes = withUnsafeBytes(of: raw) { Array($0) }
                    if !UrlGuard.isPublicAddress(bytes) { return false }
                    any = true
                }
                node = info.pointee.ai_next
            }
            return any
        }.value
    }
}
