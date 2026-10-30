// Zusammenhang: Chat/ChatEngineTools.swift, Chat/ChatEngineWriteTools.swift, Chat/ChatModel.swift, Chat/DocumentReader.swift, ParalistCore Chat/ScannedDocument.swift, ParalistCore Chat/ShiftPlan.swift, ParalistCore Chat/ChatEventDrafts.swift, ParalistCore Chat/Skills.swift, Chat/ChatEngineVision.swift (ChatVision), ParalistCore Chat/ChatPrompt.swift, ParalistCore Chat/ChatTools.swift, docs/chat.md
import Foundation
import FoundationModels
import ParalistCore

enum ChatAvailability: Equatable {
    case ready, notEligible, off, loading
}

enum ChatFailure: Equatable {
    case guardrail, context, language, cancelled, loading, generic
}

struct ChatReply: Sendable {
    var text: String
    var seen: [String]
    var drafts: [ChatDraft] = []
}

@MainActor
final class ChatEngine {
    private let data = ChatData()
    private var sessions: [String: LanguageModelSession] = [:]
    private var scans: [String: ScannedDocument] = [:]

    var availability: ChatAvailability {
        switch SystemLanguageModel.default.availability {
        case .available: return .ready
        case .unavailable(.appleIntelligenceNotEnabled): return .off
        case .unavailable(.modelNotReady): return .loading
        case .unavailable: return .notEligible
        }
    }

    var supportsThinking: Bool {
        if #available(iOS 27.0, *) { return SystemLanguageModel.default.capabilities.contains(.reasoning) }
        return false
    }

    func forget(_ threadId: String) { sessions[threadId] = nil }

    func forgetAll() { sessions = [:] }

    func forgetScans(_ hashes: [String]) { hashes.forEach { scans[$0] = nil } }

    func reply(to thread: ChatThread, snapshot: ChatSnapshot, thinking: ChatThinking) -> AsyncThrowingStream<ChatReply, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    try await self.run(thread, snapshot, continuation, thinking: thinking, budget: ChatPrompt.historyChars, retry: true)
                    continuation.finish()
                } catch {
                    self.sessions[thread.id] = nil
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(_ thread: ChatThread, _ snapshot: ChatSnapshot, _ out: AsyncThrowingStream<ChatReply, Error>.Continuation, thinking: ChatThinking, budget: Int, retry: Bool) async throws {
        guard let question = thread.lastQuestion else { return }
        data.begin(snapshot)
        let image = await scanned(thread.latestImage, snapshot)
        var plan: ChatDraft?
        if let hash = question.attachment { plan = await planDraft(hash: hash, id: data.newId(), snapshot: snapshot) }
        let extra = plan.map { $0.isEmpty ? [] : [$0] } ?? []
        let session = sessions[thread.id] ?? makeSession(thread, snapshot, budget: budget, image: question.attachment == nil ? image : "")
        sessions[thread.id] = session
        var prompt: String
        if let plan {
            prompt = ChatPrompt.withPlan(question.text, summary: ChatDrafts.planSummary(plan))
        } else {
            prompt = question.attachment == nil ? question.text : ChatPrompt.withImage(question.text, image: image)
        }
        prompt = await mentioned(prompt, question, snapshot, plan: plan != nil)
        if !extra.isEmpty { out.yield(ChatReply(text: "", seen: [], drafts: extra)) }
        do {
            var text = ""
            for try await partial in stream(session, prompt, thinking) {
                try Task.checkCancellation()
                text = partial.content
                out.yield(ChatReply(text: text, seen: data.seen, drafts: extra + data.drafts))
            }
            out.yield(ChatReply(text: text, seen: data.seen, drafts: extra + data.drafts))
        } catch {
            guard retry, Self.failure(error) == .context else { throw error }
            sessions[thread.id] = makeSession(thread, snapshot, budget: budget / 4, image: "")
            try await run(thread, snapshot, out, thinking: thinking, budget: budget / 4, retry: false)
        }
    }

    private func stream(_ session: LanguageModelSession, _ prompt: String, _ thinking: ChatThinking) -> LanguageModelSession.ResponseStream<String> {
        if #available(iOS 27.0, *), supportsThinking {
            return session.streamResponse(to: prompt, contextOptions: ContextOptions(reasoningLevel: Self.level(thinking)))
        }
        return session.streamResponse(to: prompt)
    }

    @available(iOS 27.0, *)
    private static func level(_ thinking: ChatThinking) -> ContextOptions.ReasoningLevel {
        switch thinking {
        case .fast: return .light
        case .balanced: return .moderate
        case .thorough: return .deep
        }
    }

    private func scanned(_ hash: String?, _ snapshot: ChatSnapshot) async -> String {
        guard let document = await document(hash, snapshot) else { return "" }
        return ScannedContext.format(document)
    }

    private func document(_ hash: String?, _ snapshot: ChatSnapshot) async -> ScannedDocument? {
        guard let hash, Attachment.isValidHash(hash) else { return nil }
        if let hit = scans[hash] { return hit }
        let file = snapshot.attachmentsDir.appendingPathComponent(hash)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let document = await DocumentReader.read(file, language: snapshot.languageTag) ?? ScannedDocument(text: "")
        scans[hash] = document
        return document
    }

    func planDraft(hash: String, id: String, snapshot: ChatSnapshot) async -> ChatDraft? {
        let skill = Skills.shift(in: snapshot.entries)
        guard let document = await document(hash, snapshot) else { return nil }
        var plan = ShiftPlanReader.read(document, name: skill?.name ?? "", today: snapshot.today, codes: skill?.codes ?? [:])
        if plan == nil {
            let file = snapshot.attachmentsDir.appendingPathComponent(hash)
            plan = await ChatVision.plan(image: file, document: document, name: skill?.name ?? "", today: snapshot.today)
        }
        guard let plan else { return nil }
        guard plan.rowFound else { return ChatDrafts.whichRow(id: id, names: plan.names) }
        return ChatDrafts.events(id: id, plan: plan, existing: snapshot.entries, today: snapshot.today, zone: snapshot.zone, skill: skill, fallback: snapshot.workTitle, absent: snapshot.absentTitle)
    }

    private func mentioned(_ prompt: String, _ question: ChatMessage, _ snapshot: ChatSnapshot, plan: Bool) async -> String {
        let entries = question.mentions.compactMap { id in snapshot.entries.first { $0.id == id } }
        var skills = entries.filter { Skills.isSkill($0, in: snapshot.entries) }
        if plan, let auto = Skills.shiftNote(in: snapshot.entries), !skills.contains(auto) { skills.append(auto) }
        let others = entries.filter { entry in !skills.contains { $0.id == entry.id } }
        var context = ChatTools.context(others, entries: snapshot.entries, today: snapshot.today) { snapshot.dueCards[$0] ?? 0 }
        for entry in others where entry.attachment?.mime.hasPrefix("image/") == true {
            guard let document = await document(entry.attachment?.hash, snapshot), !document.isEmpty else { continue }
            context += "\n\nphoto \"\(entry.title)\" read on the device:\n" + ScannedContext.format(document, limit: ChatTools.contextBodyChars * 2)
        }
        return ChatPrompt.withMentions(prompt, context: context, skills: Skills.instruction(skills))
    }

    private func makeSession(_ thread: ChatThread, _ snapshot: ChatSnapshot, budget: Int, image: String) -> LanguageModelSession {
        let linked = thread.links.compactMap { id in snapshot.entries.first { $0.id == id } }
        let context = ChatTools.context(linked, entries: snapshot.entries, today: snapshot.today) { snapshot.dueCards[$0] ?? 0 }
        let history = ChatPrompt.history(Array(thread.messages.dropLast()), limit: budget)
        let instructions = ChatPrompt.instructions(language: snapshot.language, today: snapshot.today, linked: context, history: history, image: image)
        let tools: [any Tool] = [
            SearchEntriesTool(data: data), ReadEntryTool(data: data), ListTasksTool(data: data), WeekOverviewTool(data: data),
            CreateFlashcardsTool(data: data), CreateTasksTool(data: data), CreateNoteTool(data: data),
        ]
        return LanguageModelSession(model: .default, tools: tools, instructions: instructions)
    }

    static func failure(_ error: Error) -> ChatFailure {
        if error is CancellationError { return .cancelled }
        if #available(iOS 27.0, *) {
            if let modelError = error as? LanguageModelError {
                switch modelError {
                case .contextSizeExceeded: return .context
                case .guardrailViolation, .refusal: return .guardrail
                case .unsupportedLanguageOrLocale: return .language
                default: return .generic
                }
            }
            if error is SystemLanguageModel.Error { return .loading }
        }
        if let generation = error as? LanguageModelSession.GenerationError {
            switch generation {
            case .exceededContextWindowSize: return .context
            case .guardrailViolation, .refusal: return .guardrail
            case .unsupportedLanguageOrLocale: return .language
            case .assetsUnavailable: return .loading
            default: return .generic
            }
        }
        return .generic
    }
}
