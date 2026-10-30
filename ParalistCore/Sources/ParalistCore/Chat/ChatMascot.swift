// Zusammenhang: Paralist/Chat/ChatMascotActor.swift, Paralist/Chat/ChatMascotScenes.swift, Paralist/Chat/ChatMascotStage.swift, Model/EntryType.swift, Chat/ChatDrafts.swift (ChatDraftKind), docs/chat.md
public enum MascotMood: CaseIterable, Sendable, Equatable {
    case glance, walk, hop, happy, tired, idle
}

public struct MascotBeat: Equatable, Sendable {
    public var mood: MascotMood
    public var direction: Double
    public var seconds: Double

    public init(mood: MascotMood, direction: Double, seconds: Double) {
        self.mood = mood
        self.direction = direction
        self.seconds = seconds
    }
}

public enum MascotTopic: CaseIterable, Sendable, Hashable {
    case flashcards, project, tasks
}

public enum MascotScene: CaseIterable, Sendable, Equatable {
    case cardsTear, cardsShove, rocketCheer, rocketRam, tasksJoy

    public var topic: MascotTopic {
        switch self {
        case .cardsTear, .cardsShove: return .flashcards
        case .rocketCheer, .rocketRam: return .project
        case .tasksJoy: return .tasks
        }
    }
}

public enum MascotScript {
    static let busyWeights: [MascotMood: Int] = [.glance: 5, .walk: 4, .hop: 2, .happy: 2, .tired: 1, .idle: 2]
    static let calmWeights: [MascotMood: Int] = [.glance: 5, .walk: 2, .hop: 1, .happy: 1, .tired: 2, .idle: 6]
    public static let calmPace = 1.8

    public static func seconds(for mood: MascotMood) -> ClosedRange<Double> {
        switch mood {
        case .glance: return 0.7...1.4
        case .walk: return 0.9...1.5
        case .hop: return 0.8...1.0
        case .happy: return 1.2...1.8
        case .tired: return 1.8...2.6
        case .idle: return 0.6...1.2
        }
    }

    public static func next(after previous: MascotMood?, calm: Bool = false, using rng: inout some RandomNumberGenerator) -> MascotBeat {
        let weights = calm ? calmWeights : busyWeights
        let pool = MascotMood.allCases.filter { $0 != previous }
        let total = pool.reduce(0) { $0 + (weights[$1] ?? 0) }
        var pick = Int.random(in: 0..<total, using: &rng)
        var mood = pool[0]
        for candidate in pool {
            let weight = weights[candidate] ?? 0
            if pick < weight {
                mood = candidate
                break
            }
            pick -= weight
        }
        let direction: Double
        switch mood {
        case .glance: direction = Double.random(in: -1...1, using: &rng)
        case .walk, .tired: direction = Bool.random(using: &rng) ? 1 : -1
        case .hop, .happy, .idle: direction = 0
        }
        let pace = calm && mood != .walk && mood != .hop ? calmPace : 1
        return MascotBeat(mood: mood, direction: direction, seconds: Double.random(in: seconds(for: mood), using: &rng) * pace)
    }

    public static func quip(count: Int, avoiding previous: Int?, using rng: inout some RandomNumberGenerator) -> Int {
        guard count > 1 else { return 0 }
        guard let previous, previous >= 0, previous < count else { return Int.random(in: 0..<count, using: &rng) }
        let pick = Int.random(in: 0..<(count - 1), using: &rng)
        return pick >= previous ? pick + 1 : pick
    }
}

public enum MascotScenes {
    public static let beatsBetween = 5...10

    public static func topics(draftKinds: [ChatDraftKind], entryTypes: [EntryType]) -> Set<MascotTopic> {
        var topics: Set<MascotTopic> = []
        for kind in draftKinds {
            switch kind {
            case .flashcards: topics.insert(.flashcards)
            case .tasks: topics.insert(.tasks)
            case .note, .events: break
            }
        }
        for type in entryTypes {
            switch type {
            case .flashcard, .deck: topics.insert(.flashcards)
            case .project: topics.insert(.project)
            case .task: topics.insert(.tasks)
            default: break
            }
        }
        return topics
    }

    public static func pick(topics: Set<MascotTopic>, avoiding previous: MascotScene?, using rng: inout some RandomNumberGenerator) -> MascotScene? {
        var pool = MascotScene.allCases.filter { topics.contains($0.topic) }
        if pool.count > 1, let previous { pool.removeAll { $0 == previous } }
        guard !pool.isEmpty else { return nil }
        return pool[Int.random(in: 0..<pool.count, using: &rng)]
    }

    public static func beatsUntilScene(using rng: inout some RandomNumberGenerator) -> Int {
        Int.random(in: beatsBetween, using: &rng)
    }
}
