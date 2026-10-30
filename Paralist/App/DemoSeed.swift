// Zusammenhang: App/LaunchOptions.swift, App/AppPaths.swift (isDemo), App/AppModel.swift, Files/AttachmentImporter.swift, ParalistCore Chat/ChatStore.swift
import Foundation
import ParalistCore
import UIKit

enum DemoSeed {
    static let videoId = "demo-video-0001"
    static let taskId = "demo-task-00000001"
    static let chatId = "demo-chat-00000001"
    static let planChatId = "demo-chat-00000003"
    static let photoId = "demo-photo-0001"
    static let tallPhotoId = "demo-photo-0002"

    static func fill(_ library: EntryLibrary) {
        try? FileManager.default.removeItem(at: library.store.root)
        let fresh = EntryLibrary(root: library.store.root)
        let now = Date()
        let today = Day.of(now, in: .current)
        func make(_ id: String, _ type: EntryType, _ title: String, ago: Double = 0, _ change: (inout Entry) -> Void = { _ in }) {
            var e = Entry(id: id, type: type, title: title, created: now.addingTimeInterval(-ago * 3600), updated: now.addingTimeInterval(-ago * 3600))
            e.status = type.hasStatus ? .open : nil
            change(&e)
            _ = try? fresh.store.write(e)
        }
        make("demo-project-0001", .project, "Umzug nach Leipzig", ago: 40) { $0.due = today.adding(days: 3) }
        make("demo-area-00000001", .area, "Gesundheit", ago: 90)
        make("demo-area-00000002", .area, "Finanzen", ago: 120)
        make(videoId, .bookmark, "Rick Astley – Never Gonna Give You Up", ago: 2) {
            $0.url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            $0.favorite = true
            $0.body = "Für den **Freitagabend** merken.\n\n- [x] anschauen\n- [ ] teilen\n"
        }
        make("demo-bookmark-0002", .bookmark, "PARA-Methode erklärt", ago: 5) { $0.url = "https://fortelabs.com/blog/para/"; $0.places = ["demo-area-00000001"] }
        make("demo-task-00000001", .task, "Umzugskartons bestellen", ago: 3) {
            $0.due = today
            $0.places = ["demo-project-0001"]
            $0.pinned = true
            let first = today.adding(days: 1).at(hour: 8, in: .current)
            $0.reminders = [first, today.adding(days: 2).at(hour: 18, in: .current)]
            $0.setReminderNote("Maße vom Flur mitnehmen", at: first)
        }
        make("demo-task-00000002", .task, "Steuererklärung abgeben", ago: 30) { $0.due = today.adding(days: -1) }
        make("demo-task-00000003", .task, "Zahnarzt anrufen", ago: 8) { $0.status = .inProgress }
        make("demo-task-00000004", .task, "Wohnung kündigen", ago: 50) { $0.due = today; $0.status = .done; $0.doneAt = now.addingTimeInterval(-7200) }
        make("demo-task-00000005", .task, "Altes Sofa verkaufen", ago: 300) { $0.status = .done; $0.doneAt = now.addingTimeInterval(-250 * 3600); $0.archived = true }
        make("demo-task-00000006", .task, "Nachsendeauftrag prüfen", ago: 260) { $0.status = .inProgress; $0.archived = true }
        make("demo-note-00000001", .note, "Ideen fürs Wochenende", ago: 1) { $0.body = "Flohmarkt, Radtour an die Seen, neues Café testen.\n" }
        make("demo-note-00000002", .note, "Zitat", ago: 26) { $0.body = "> Ordnung ist das halbe Leben.\n" }
        make("demo-event-0000001", .event, "Team-Meeting", ago: 20) {
            $0.start = today.at(hour: 10, in: .current)
            $0.end = today.at(hour: 11, minute: 30, in: .current)
        }
        make("demo-event-0000002", .event, "Laufen im Park", ago: 20) {
            $0.start = today.at(hour: 18, in: .current)
            $0.end = today.at(hour: 19, in: .current)
        }
        make("demo-event-0000003", .event, "Geburtstag Mama", ago: 60) { $0.start = today.adding(days: 2).startOfDay(in: .current); $0.allDay = true }
        make("demo-tag-skill-001", .tag, Skills.tagTitle, ago: 80)
        make("demo-note-skill-01", .note, L.s("skill_shift_title"), ago: 80) {
            $0.links = ["demo-tag-skill-001"]
            $0.body = L.s("skill_shift_text") + "\n"
            $0.extras = [Skills.nameKey: "Muster, Erika"]
        }
        func photo(_ id: String, _ title: String, width: CGFloat, height: CGFloat, ago: Double) {
            let size = CGSize(width: width, height: height)
            let image = UIGraphicsImageRenderer(size: size).image { ctx in
                let colors = [UIColor(red: 0.98, green: 0.64, blue: 0.36, alpha: 1).cgColor, UIColor(red: 0.22, green: 0.32, blue: 0.62, alpha: 1).cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                    ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
                }
                UIColor.white.withAlphaComponent(0.85).setFill()
                let radius = min(width, height) * 0.18
                ctx.cgContext.fillEllipse(in: CGRect(x: width * 0.62 - radius, y: height * 0.3 - radius, width: radius * 2, height: radius * 2))
            }
            guard let data = image.jpegData(compressionQuality: 0.85),
                  case .success(let attachment) = AttachmentImporter.importData(data, name: "\(id).jpg", into: fresh.store) else { return }
            make(id, .file, title, ago: ago) { $0.attachment = attachment }
        }
        photo(photoId, "Strand am Abend", width: 1600, height: 900, ago: 4)
        photo(tallPhotoId, "Leuchtturm", width: 900, height: 1600, ago: 6)
        make("demo-deck-00000001", .deck, "Spanisch A2", ago: 70)
        for (i, pair) in [("la casa", "das Haus"), ("el perro", "der Hund"), ("la ventana", "das Fenster")].enumerated() {
            make("demo-card-0000000\(i)", .flashcard, pair.0, ago: 60) { $0.body = pair.1 + "\n"; $0.deck = "demo-deck-00000001" }
        }
        let chats = ChatStore(root: library.store.root)
        func chat(_ id: String, ago: Double, _ lines: [(ChatRole, String)], drafts: [ChatDraft] = []) {
            var thread = ChatThread(id: id, created: now.addingTimeInterval(-ago * 3600))
            for (i, line) in lines.enumerated() {
                thread.append(ChatMessage(id: "\(id)-m\(i)", role: line.0, text: line.1, at: now.addingTimeInterval(-ago * 3600 + Double(i) * 30)))
            }
            if !drafts.isEmpty { thread.messages[thread.messages.count - 1].drafts = drafts }
            _ = try? chats.write(thread)
        }
        chat(chatId, ago: 1, [
            (.user, "Was steht diese Woche an?"),
            (.assistant, "Diese Woche sind **zwei Aufgaben** offen:\n\n- Umzugskartons bestellen, fällig heute\n- Steuererklärung abgeben, überfällig\n\nAußerdem endet das Projekt *Umzug nach Leipzig* in drei Tagen."),
            (.user, "Erstelle mir 6 Karteikarten mit einfachen Wörtern auf Französisch."),
            (.assistant, "Ich habe sechs Karteikarten für ein neues Kartendeck vorbereitet."),
        ], drafts: [ChatDrafts.flashcards(id: "demo-draft-0000001", deck: "Französisch", cards: [
            ("le chien", "der Hund"), ("la maison", "das Haus"), ("le pain", "das Brot"),
            ("l'eau", "das Wasser"), ("le livre", "das Buch"), ("merci", "danke"),
        ])])
        chat("demo-chat-00000002", ago: 30, [
            (.user, "Welche Vokabeln lerne ich gerade?"),
            (.assistant, "Im Stapel **Spanisch A2** liegen drei Karten: *la casa*, *el perro* und *la ventana*."),
        ])
        if let plan = ShiftPlanReader.read(shiftPlan(today), name: "Erika Muster", today: today) {
            let draft = ChatDrafts.events(id: "demo-draft-0000002", plan: plan, existing: [], today: today, zone: .current, fallback: L.s("shift_work"))
            chat(planChatId, ago: 0.5, [
                (.user, "Trag mir meine Schichten ein."),
                (.assistant, "Ich habe deine Schichten dieser Woche als Termine vorbereitet."),
            ], drafts: [draft])
        }
    }

    static func shiftPlan(_ today: Day) -> ScannedDocument {
        let monday = today.adding(days: 1 - today.weekday)
        let labels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        var head = ["Name"]
        var sub = [""]
        for i in 0..<7 {
            let day = monday.adding(days: i)
            head += ["\(labels[i]) \(String(format: "%02d.%02d", day.day, day.month))", ""]
            sub += ["Std.", "Zeit"]
        }
        let own = ["Muster, Erika", "6.92", "06:00-13:25/", "", "ABW", "8.5", "13:00-21:00", "", "f", "7.5", "13:00-21:00", "8", "22:00-06:30", "", "-"]
        let other = ["Beispiel, Max", "", "f", "7.5", "13:00-21:00", "", "f", "6.92", "06:00-13:25", "", "ABW", "", "", "", ""]
        return ScannedDocument(text: "Wochenplan", tables: [ScannedTable(rows: [head, sub, own, other])])
    }
}
