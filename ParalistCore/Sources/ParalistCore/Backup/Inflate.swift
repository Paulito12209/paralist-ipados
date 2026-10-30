// Zusammenhang: Backup/Zip.swift (Methode 8), Tests/ParalistCoreTests/BackupTests.swift
import Foundation

public struct InflateError: Error, Equatable {
    public let tooLarge: Bool
}

public enum Inflate {
    private static let lengthBase = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
    private static let lengthExtra = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
    private static let distBase = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
    private static let distExtra = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
    private static let order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

    private struct Huffman {
        var counts = [Int](repeating: 0, count: 16)
        var symbols: [Int]

        init(_ lengths: [Int]) {
            symbols = [Int](repeating: 0, count: lengths.count)
            for l in lengths { counts[l] += 1 }
            counts[0] = 0
            var offs = [Int](repeating: 0, count: 16)
            for i in 1..<16 { offs[i] = offs[i - 1] + counts[i - 1] }
            for (s, l) in lengths.enumerated() where l != 0 {
                symbols[offs[l]] = s
                offs[l] += 1
            }
        }
    }

    private struct Bits {
        let bytes: [UInt8]
        var pos = 0
        var bit = 0

        mutating func read(_ n: Int) throws -> Int {
            var value = 0
            for i in 0..<n {
                guard pos < bytes.count else { throw InflateError(tooLarge: false) }
                value |= Int((bytes[pos] >> UInt8(bit)) & 1) << i
                bit += 1
                if bit == 8 { bit = 0; pos += 1 }
            }
            return value
        }

        mutating func decode(_ h: Huffman) throws -> Int {
            var code = 0, first = 0, index = 0
            for len in 1..<16 {
                code |= try read(1)
                let count = h.counts[len]
                if code - count < first { return h.symbols[index + (code - first)] }
                index += count
                first += count
                first <<= 1
                code <<= 1
            }
            throw InflateError(tooLarge: false)
        }
    }

    public static func raw(_ input: Data, maxOutput: Int) throws -> Data {
        var bits = Bits(bytes: [UInt8](input))
        var out = [UInt8]()
        out.reserveCapacity(min(maxOutput, input.count * 4))
        var last = false
        while !last {
            last = try bits.read(1) == 1
            switch try bits.read(2) {
            case 0:
                if bits.bit != 0 { bits.bit = 0; bits.pos += 1 }
                guard bits.pos + 4 <= bits.bytes.count else { throw InflateError(tooLarge: false) }
                let len = Int(bits.bytes[bits.pos]) | Int(bits.bytes[bits.pos + 1]) << 8
                bits.pos += 4
                guard bits.pos + len <= bits.bytes.count else { throw InflateError(tooLarge: false) }
                if out.count + len > maxOutput { throw InflateError(tooLarge: true) }
                out.append(contentsOf: bits.bytes[bits.pos..<(bits.pos + len)])
                bits.pos += len
            case 1:
                var lengths = [Int](repeating: 8, count: 288)
                for i in 144..<256 { lengths[i] = 9 }
                for i in 256..<280 { lengths[i] = 7 }
                try block(&bits, &out, Huffman(lengths), Huffman([Int](repeating: 5, count: 30)), maxOutput)
            case 2:
                let hlit = try bits.read(5) + 257
                let hdist = try bits.read(5) + 1
                let hclen = try bits.read(4) + 4
                var codeLengths = [Int](repeating: 0, count: 19)
                for i in 0..<hclen { codeLengths[order[i]] = try bits.read(3) }
                let codeTree = Huffman(codeLengths)
                var lengths: [Int] = []
                while lengths.count < hlit + hdist {
                    let sym = try bits.decode(codeTree)
                    switch sym {
                    case 0..<16: lengths.append(sym)
                    case 16:
                        guard let prev = lengths.last else { throw InflateError(tooLarge: false) }
                        lengths += [Int](repeating: prev, count: 3 + (try bits.read(2)))
                    case 17: lengths += [Int](repeating: 0, count: 3 + (try bits.read(3)))
                    default: lengths += [Int](repeating: 0, count: 11 + (try bits.read(7)))
                    }
                }
                guard lengths.count == hlit + hdist else { throw InflateError(tooLarge: false) }
                try block(&bits, &out, Huffman(Array(lengths[0..<hlit])), Huffman(Array(lengths[hlit...])), maxOutput)
            default:
                throw InflateError(tooLarge: false)
            }
        }
        return Data(out)
    }

    private static func block(_ bits: inout Bits, _ out: inout [UInt8], _ lit: Huffman, _ dist: Huffman, _ maxOutput: Int) throws {
        while true {
            let sym = try bits.decode(lit)
            if sym < 256 {
                if out.count >= maxOutput { throw InflateError(tooLarge: true) }
                out.append(UInt8(sym))
            } else if sym == 256 {
                return
            } else {
                let li = sym - 257
                guard li < lengthBase.count else { throw InflateError(tooLarge: false) }
                let length = lengthBase[li] + (try bits.read(lengthExtra[li]))
                let di = try bits.decode(dist)
                guard di < distBase.count else { throw InflateError(tooLarge: false) }
                let distance = distBase[di] + (try bits.read(distExtra[di]))
                guard distance <= out.count else { throw InflateError(tooLarge: false) }
                if out.count + length > maxOutput { throw InflateError(tooLarge: true) }
                let start = out.count - distance
                for i in 0..<length { out.append(out[start + i]) }
            }
        }
    }
}
