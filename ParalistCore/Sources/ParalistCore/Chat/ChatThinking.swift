// Zusammenhang: Paralist/Chat/ChatEngine.swift (reasoningLevel), Paralist/Chat/ChatInputBar.swift, Paralist/App/AppPrefs.swift, docs/chat.md
public enum ChatThinking: String, CaseIterable, Sendable {
    case fast = "schnell"
    case balanced = "ausgewogen"
    case thorough = "gruendlich"

    public static let standard: ChatThinking = .fast

    public static func fromKey(_ key: String?) -> ChatThinking {
        key.flatMap(ChatThinking.init(rawValue:)) ?? standard
    }
}
