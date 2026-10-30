// Zusammenhang: Pages/ListPage.swift, Pages/OverviewPage.swift, Pages/OverviewParts.swift (FillZone), Entries/EmptyViews.swift (EmptyHint), Entries/TypeLook.swift (ListTitles), Capture/CaptureFlow.swift, Shell/Router.swift
import ParalistCore
import SwiftUI

enum ListAdd: Equatable {
    case compose(EntryType)
    case capture(CaptureKind)
    case create(String)

    static func of(_ kind: ListKind, filter: ListFilter = .all) -> ListAdd {
        switch filter {
        case .areas: return .compose(.area)
        case .projects: return .compose(.project)
        case .tasks: return .compose(.task)
        case .events: return .compose(.event)
        case .notes: return .compose(.note)
        case .documents: return .compose(.document)
        case .bookmarks: return .compose(.bookmark)
        case .flashcards: return .compose(.flashcard)
        case .images: return .capture(.photo)
        case .videos: return .capture(.video)
        case .audios: return .capture(.audio)
        case .files: return .capture(.files)
        case .all: break
        }
        switch kind {
        case .areas: return .compose(.area)
        case .projects: return .compose(.project)
        case .tasks: return .compose(.task)
        case .notes, .inbox: return .compose(.note)
        case .events: return .compose(.event)
        case .bookmarks: return .compose(.bookmark)
        case .flashcards: return .compose(.flashcard)
        case .tags: return .compose(.tag)
        case .files: return .capture(.files)
        case .resources: return .create("add_new_resource")
        case .all, .marked, .pinned, .favorites, .archive: return .create("add_new_entry")
        }
    }

    static func creates(_ kind: ListKind) -> Bool {
        ![.all, .marked, .pinned, .favorites, .archive].contains(kind)
    }

    var label: String {
        switch self {
        case .compose(let type):
            switch type {
            case .note: return L.s("add_new_note")
            case .task: return L.s("add_new_task")
            case .event: return L.s("add_new_event")
            case .project: return L.s("add_new_project")
            case .area: return L.s("add_new_area")
            case .bookmark: return L.s("add_new_bookmark")
            case .document: return L.s("add_new_document")
            case .flashcard, .deck: return L.s("add_new_flashcard")
            case .tag: return L.s("add_new_tag")
            case .file: return L.s("add_new_file")
            }
        case .capture(let kind):
            switch kind {
            case .photo: return L.s("add_new_photo")
            case .video: return L.s("add_new_video")
            case .audio: return L.s("add_new_audio")
            case .files: return L.s("add_new_file")
            }
        case .create(let key): return L.s(key)
        }
    }

    static func hint(_ kind: ListKind, tappable: Bool = true) -> String {
        guard tappable, creates(kind) else { return ListTitles.empty(kind) }
        switch kind {
        case .inbox: return L.s("empty_tap_inbox")
        case .notes: return L.s("empty_tap_note")
        case .tasks: return L.s("empty_tap_task")
        case .events: return L.s("empty_tap_event")
        case .projects: return L.s("empty_tap_project")
        case .areas: return L.s("empty_tap_area")
        case .resources: return L.s("empty_tap_resource")
        case .bookmarks: return L.s("empty_tap_bookmark")
        case .files: return L.s("empty_tap_file")
        case .tags: return L.s("empty_tap_tag")
        case .flashcards: return L.s("empty_tap_flashcard")
        case .all, .marked, .pinned, .favorites, .archive: return ListTitles.empty(kind)
        }
    }

    @MainActor
    func run(router: Router, model: AppModel) {
        switch self {
        case .compose(let type): router.compose(ComposerRequest(type: type))
        case .capture(let kind): CaptureFlow.start(kind, router: router, model: model)
        case .create: router.openCreate()
        }
    }
}
