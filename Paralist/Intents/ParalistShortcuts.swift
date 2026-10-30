// Zusammenhang: Paralist/Intents/TypedEntryIntents.swift, Paralist/Intents/OpenEntryIntent.swift, Paralist/Intents/TodayIntent.swift, Paralist/Resources/AppShortcuts.xcstrings, Paralist/App/ParalistApp.swift, docs/siri.md
import AppIntents

struct ParalistShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NewNoteIntent(),
            phrases: [
                "Neue Notiz in \(.applicationName)",
                "Neue Notiz für \(.applicationName)",
                "Erstelle eine Notiz in \(.applicationName)",
                "Erstell mir eine Notiz in \(.applicationName)",
                "Notiz in \(.applicationName) anlegen",
                "Neue \(.applicationName)-Notiz",
            ],
            shortTitle: "siri_new_note",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NewTaskIntent(),
            phrases: [
                "Neue Aufgabe in \(.applicationName)",
                "Neue Aufgabe für \(.applicationName)",
                "Erstelle eine Aufgabe in \(.applicationName)",
                "Erstell mir eine Aufgabe in \(.applicationName)",
                "Aufgabe in \(.applicationName) anlegen",
                "Neue \(.applicationName)-Aufgabe",
            ],
            shortTitle: "siri_new_task",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NewEventIntent(),
            phrases: [
                "Neuer Termin in \(.applicationName)",
                "Neuer Termin für \(.applicationName)",
                "Erstelle einen Termin in \(.applicationName)",
                "Erstell mir einen Termin in \(.applicationName)",
                "Termin in \(.applicationName) anlegen",
                "Neuer \(.applicationName)-Termin",
            ],
            shortTitle: "siri_new_event",
            systemImageName: "calendar.badge.plus"
        )
        AppShortcut(
            intent: NewProjectIntent(),
            phrases: [
                "Neues Projekt in \(.applicationName)",
                "Neues Projekt für \(.applicationName)",
                "Erstelle ein Projekt in \(.applicationName)",
                "Erstell mir ein Projekt in \(.applicationName)",
                "Projekt in \(.applicationName) anlegen",
                "Neues \(.applicationName)-Projekt",
            ],
            shortTitle: "siri_new_project",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NewAreaIntent(),
            phrases: [
                "Neuer Arbeitsbereich in \(.applicationName)",
                "Neuer Arbeitsbereich für \(.applicationName)",
                "Erstelle einen Arbeitsbereich in \(.applicationName)",
                "Erstell mir einen Arbeitsbereich in \(.applicationName)",
                "Arbeitsbereich in \(.applicationName) anlegen",
                "Neuer \(.applicationName)-Arbeitsbereich",
            ],
            shortTitle: "siri_new_area",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NewDocumentIntent(),
            phrases: [
                "Neues Dokument in \(.applicationName)",
                "Neues Dokument für \(.applicationName)",
                "Erstelle ein Dokument in \(.applicationName)",
                "Erstell mir ein Dokument in \(.applicationName)",
                "Dokument in \(.applicationName) anlegen",
                "Neues \(.applicationName)-Dokument",
            ],
            shortTitle: "siri_new_document",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenEntryIntent(),
            phrases: [
                "Öffne \(\.$target) in \(.applicationName)",
                "Öffne \(.applicationName)-Eintrag",
            ],
            shortTitle: "siri_open_short",
            systemImageName: "arrow.up.forward.app"
        )
        AppShortcut(
            intent: TodayIntent(),
            phrases: [
                "Was steht heute an in \(.applicationName)",
                "Was steht heute in \(.applicationName) an",
            ],
            shortTitle: "siri_today_short",
            systemImageName: "sun.max"
        )
    }
}
