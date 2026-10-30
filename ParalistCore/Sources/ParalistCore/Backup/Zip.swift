// Zusammenhang: Backup/Inflate.swift, Backup/Checksums.swift, Backup/BackupFormat.swift, Backup/SafeUnzip.swift, Backup/BackupWriter.swift
import Foundation

public struct CentralEntry: Equatable, Sendable {
    public let name: String
    public let uncompressed: Int64
    public let compressed: Int64
    public let method: Int
    public let crc: UInt32
    public let localOffset: Int64
    public var isDirectory: Bool { name.hasSuffix("/") }
}

public struct ZipReader {
    private let data: Data
    public let entries: [CentralEntry]

    public init(url: URL, limits: BackupLimits) throws {
        guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else { throw BackupRejected(.unreadable) }
        try self.init(data: data, limits: limits)
    }

    public init(data: Data, limits: BackupLimits) throws {
        self.data = data
        entries = try Self.inspect(data, limits)
    }

    private static func u16(_ d: Data, _ i: Int) -> Int { Int(d[d.startIndex + i]) | Int(d[d.startIndex + i + 1]) << 8 }
    private static func u32(_ d: Data, _ i: Int) -> Int64 { Int64(u16(d, i)) | Int64(u16(d, i + 2)) << 16 }

    private static func inspect(_ d: Data, _ limits: BackupLimits) throws -> [CentralEntry] {
        guard d.count >= 22 else { throw BackupRejected(.notAZip) }
        let lowest = max(0, d.count - 65_557)
        var eocd = -1
        var i = d.count - 22
        while i >= lowest {
            if u32(d, i) == 0x0605_4b50 { eocd = i; break }
            i -= 1
        }
        guard eocd >= 0 else { throw BackupRejected(.notAZip) }
        let count = u16(d, eocd + 10)
        let size = u32(d, eocd + 12)
        let offset = u32(d, eocd + 16)
        if count == 0xFFFF || size == 0xFFFF_FFFF || offset == 0xFFFF_FFFF { throw BackupRejected(.notAZip) }
        if count > limits.maxEntries { throw BackupRejected(.tooManyEntries) }
        if size > 32 * 1024 * 1024 || offset + size > Int64(d.count) { throw BackupRejected(.notAZip) }
        var pos = Int(offset)
        let end = Int(offset + size)
        var total: Int64 = 0
        var out: [CentralEntry] = []
        for _ in 0..<count {
            guard pos + 46 <= end, u32(d, pos) == 0x0201_4b50 else { throw BackupRejected(.notAZip) }
            let host = u16(d, pos + 4) >> 8
            let method = u16(d, pos + 10)
            let crc = UInt32(u32(d, pos + 16))
            let compressed = u32(d, pos + 20)
            let uncompressed = u32(d, pos + 24)
            let nameLength = u16(d, pos + 28)
            let extraLength = u16(d, pos + 30)
            let commentLength = u16(d, pos + 32)
            let external = u32(d, pos + 38)
            let local = u32(d, pos + 42)
            guard pos + 46 + nameLength <= end else { throw BackupRejected(.notAZip) }
            let nameData = d.subdata(in: (d.startIndex + pos + 46)..<(d.startIndex + pos + 46 + nameLength))
            guard let name = String(data: nameData, encoding: .utf8) else { throw BackupRejected(.unsafePath) }
            if !BackupFormat.isSafeName(name) { throw BackupRejected(.unsafePath) }
            if host == 3 && ((external >> 16) & 0xF000) == 0xA000 { throw BackupRejected(.symlink) }
            if uncompressed > limits.maxFileBytes { throw BackupRejected(.tooLarge) }
            total += uncompressed
            if total > limits.maxTotalBytes { throw BackupRejected(.tooLarge) }
            if compressed > 0 && uncompressed > limits.ratioFloorBytes && uncompressed / compressed > limits.maxRatio {
                throw BackupRejected(.suspiciousRatio)
            }
            out.append(CentralEntry(name: name, uncompressed: uncompressed, compressed: compressed, method: method, crc: crc, localOffset: local))
            pos += 46 + nameLength + extraLength + commentLength
        }
        return out
    }

    public func read(_ entry: CentralEntry, maxBytes: Int64) throws -> Data {
        let d = data
        let at = Int(entry.localOffset)
        guard at + 30 <= d.count, Self.u32(d, at) == 0x0403_4b50 else { throw BackupRejected(.notAZip) }
        let start = at + 30 + Self.u16(d, at + 26) + Self.u16(d, at + 28)
        let stop = start + Int(entry.compressed)
        guard stop <= d.count else { throw BackupRejected(.notAZip) }
        let raw = d.subdata(in: (d.startIndex + start)..<(d.startIndex + stop))
        let limit = Int(min(maxBytes, entry.uncompressed))
        let out = try decode(entry, raw, limit, maxBytes)
        guard CRC32.checksum(out) == entry.crc else { throw BackupRejected(.unreadable) }
        return out
    }

    private func decode(_ entry: CentralEntry, _ raw: Data, _ limit: Int, _ maxBytes: Int64) throws -> Data {
        switch entry.method {
        case 0:
            if Int64(raw.count) > maxBytes { throw BackupRejected(.tooLarge) }
            return raw
        case 8:
            do {
                let out = try Inflate.raw(raw, maxOutput: limit)
                guard out.count == Int(entry.uncompressed) else { throw BackupRejected(.unreadable) }
                return out
            } catch let error as InflateError {
                throw BackupRejected(error.tooLarge ? .tooLarge : .unreadable)
            }
        default:
            throw BackupRejected(.unreadable)
        }
    }
}

public final class ZipWriter {
    private let handle: FileHandle
    private var central = Data()
    private var count = 0
    private var offset: Int64 = 0

    public init(url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        handle = try FileHandle(forWritingTo: url)
    }

    public func add(_ name: String, _ data: Data, modified: Date = Date()) throws {
        let nameData = Data(name.utf8)
        let crc = CRC32.checksum(data)
        let (time, date) = Self.dosTime(modified)
        var local = Data()
        Self.put32(&local, 0x0403_4b50)
        Self.put16(&local, 20); Self.put16(&local, 0x0800); Self.put16(&local, 0)
        Self.put16(&local, time); Self.put16(&local, date)
        Self.put32(&local, crc); Self.put32(&local, UInt32(data.count)); Self.put32(&local, UInt32(data.count))
        Self.put16(&local, nameData.count); Self.put16(&local, 0)
        local.append(nameData)
        try handle.write(contentsOf: local)
        try handle.write(contentsOf: data)
        Self.put32(&central, 0x0201_4b50)
        Self.put16(&central, 20); Self.put16(&central, 20); Self.put16(&central, 0x0800); Self.put16(&central, 0)
        Self.put16(&central, time); Self.put16(&central, date)
        Self.put32(&central, crc); Self.put32(&central, UInt32(data.count)); Self.put32(&central, UInt32(data.count))
        Self.put16(&central, nameData.count); Self.put16(&central, 0); Self.put16(&central, 0)
        Self.put16(&central, 0); Self.put16(&central, 0); Self.put32(&central, 0); Self.put32(&central, UInt32(offset))
        central.append(nameData)
        offset += Int64(local.count + data.count)
        count += 1
    }

    public func finish() throws {
        var end = Data()
        Self.put32(&end, 0x0605_4b50)
        Self.put16(&end, 0); Self.put16(&end, 0); Self.put16(&end, count); Self.put16(&end, count)
        Self.put32(&end, UInt32(central.count)); Self.put32(&end, UInt32(offset)); Self.put16(&end, 0)
        try handle.write(contentsOf: central)
        try handle.write(contentsOf: end)
        try handle.close()
    }

    private static func put16(_ d: inout Data, _ v: Int) { d.append(UInt8(v & 0xFF)); d.append(UInt8((v >> 8) & 0xFF)) }
    private static func put32(_ d: inout Data, _ v: UInt32) { for i in 0..<4 { d.append(UInt8((v >> (UInt32(i) * 8)) & 0xFF)) } }

    private static func dosTime(_ date: Date) -> (Int, Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let time = (c.hour ?? 0) << 11 | (c.minute ?? 0) << 5 | (c.second ?? 0) / 2
        let day = max((c.year ?? 1980) - 1980, 0) << 9 | (c.month ?? 1) << 5 | (c.day ?? 1)
        return (time, day)
    }
}
