// Zusammenhang: Store/EntryStore.swift, Library/EntryLibrary.swift, Markdown/EntryCodec.swift
import Foundation

public protocol IdGenerator: Sendable {
    func next() -> String
}

public protocol Clock: Sendable {
    func now() -> Date
}

public struct SecureIds: IdGenerator {
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567")
    private static let length = 20

    public init() {}

    public func next() -> String {
        var generator = SystemRandomNumberGenerator()
        var out = String(Self.alphabet[Int(UInt8.random(in: 0...255, using: &generator)) % 26])
        for _ in 1..<Self.length {
            out.append(Self.alphabet[Int(UInt8.random(in: 0...255, using: &generator)) % Self.alphabet.count])
        }
        return out
    }
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date { Date() }
}

public struct FixedClock: Clock {
    public let date: Date
    public init(_ date: Date) { self.date = date }
    public func now() -> Date { date }
}
