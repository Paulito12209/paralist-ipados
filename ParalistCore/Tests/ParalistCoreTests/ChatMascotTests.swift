// Zusammenhang: ParalistCore Chat/ChatMascot.swift
import Testing
@testable import ParalistCore

struct ChatMascotTests {
    struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    @Test func neverRepeatsTheSameMoodTwice() {
        var rng = Seeded(state: 7)
        var previous: MascotMood? = nil
        for _ in 0..<500 {
            let beat = MascotScript.next(after: previous, using: &rng)
            #expect(beat.mood != previous)
            previous = beat.mood
        }
    }

    @Test func everyMoodShowsUpOverTime() {
        var rng = Seeded(state: 3)
        var seen: Set<MascotMood> = []
        var previous: MascotMood? = nil
        for _ in 0..<400 {
            let beat = MascotScript.next(after: previous, using: &rng)
            seen.insert(beat.mood)
            previous = beat.mood
        }
        #expect(seen == Set(MascotMood.allCases))
    }

    @Test func secondsAndDirectionStayInRange() {
        var rng = Seeded(state: 11)
        var previous: MascotMood? = nil
        for _ in 0..<300 {
            let beat = MascotScript.next(after: previous, using: &rng)
            #expect(MascotScript.seconds(for: beat.mood).contains(beat.seconds))
            #expect(beat.direction >= -1 && beat.direction <= 1)
            switch beat.mood {
            case .walk, .tired: #expect(abs(beat.direction) == 1)
            case .hop, .happy, .idle: #expect(beat.direction == 0)
            case .glance: break
            }
            previous = beat.mood
        }
    }

    @Test func sameSeedGivesSameScript() {
        var a = Seeded(state: 42)
        var b = Seeded(state: 42)
        for _ in 0..<20 {
            #expect(MascotScript.next(after: nil, using: &a) == MascotScript.next(after: nil, using: &b))
        }
    }

    @Test func quipAvoidsThePreviousOne() {
        var rng = Seeded(state: 5)
        for previous in 0..<4 {
            for _ in 0..<50 {
                let pick = MascotScript.quip(count: 4, avoiding: previous, using: &rng)
                #expect(pick != previous)
                #expect(pick >= 0 && pick < 4)
            }
        }
    }

    @Test func calmScriptIsSlowerAndSitsMore() {
        var rng = Seeded(state: 21)
        var previous: MascotMood? = nil
        var idle = 0
        var walks = 0
        for _ in 0..<400 {
            let beat = MascotScript.next(after: previous, calm: true, using: &rng)
            if beat.mood == .idle { idle += 1 }
            if beat.mood == .walk { walks += 1 }
            let range = MascotScript.seconds(for: beat.mood)
            if beat.mood == .walk || beat.mood == .hop {
                #expect(range.contains(beat.seconds))
            } else {
                #expect(beat.seconds >= range.lowerBound * MascotScript.calmPace && beat.seconds <= range.upperBound * MascotScript.calmPace)
            }
            previous = beat.mood
        }
        #expect(idle > walks)
    }

    @Test func topicsComeFromDraftsAndEntries() {
        #expect(MascotScenes.topics(draftKinds: [], entryTypes: []).isEmpty)
        #expect(MascotScenes.topics(draftKinds: [.flashcards], entryTypes: []) == [.flashcards])
        #expect(MascotScenes.topics(draftKinds: [.note], entryTypes: [.note, .bookmark, .file]).isEmpty)
        #expect(MascotScenes.topics(draftKinds: [.tasks], entryTypes: [.project, .deck]) == [.tasks, .project, .flashcards])
        #expect(MascotScenes.topics(draftKinds: [], entryTypes: [.task, .flashcard]) == [.tasks, .flashcards])
    }

    @Test func scenesMatchTopicsAndAvoidRepeats() {
        var rng = Seeded(state: 13)
        #expect(MascotScenes.pick(topics: [], avoiding: nil, using: &rng) == nil)
        var seen: Set<MascotScene> = []
        var previous: MascotScene? = nil
        for _ in 0..<300 {
            let scene = MascotScenes.pick(topics: [.flashcards, .project], avoiding: previous, using: &rng)
            #expect(scene != nil)
            #expect(scene != previous)
            #expect(scene?.topic != .tasks)
            if let scene { seen.insert(scene) }
            previous = scene
        }
        #expect(seen == [.cardsTear, .cardsShove, .rocketCheer, .rocketRam])
        #expect(MascotScenes.pick(topics: [.tasks], avoiding: .tasksJoy, using: &rng) == .tasksJoy)
        for _ in 0..<50 { #expect(MascotScenes.beatsBetween.contains(MascotScenes.beatsUntilScene(using: &rng))) }
    }

    @Test func quipWithoutPreviousCoversAll() {
        var rng = Seeded(state: 9)
        var seen: Set<Int> = []
        for _ in 0..<200 { seen.insert(MascotScript.quip(count: 4, avoiding: nil, using: &rng)) }
        #expect(seen == [0, 1, 2, 3])
        #expect(MascotScript.quip(count: 1, avoiding: 0, using: &rng) == 0)
    }
}
