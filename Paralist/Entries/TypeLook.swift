// Zusammenhang: ParalistCore Model/EntryType.swift, ParalistCore Library/LinkPicker.swift (LinkTab), ParalistCore Links/LinkBrand.swift, Icons/AppIcons.swift, Entries/EntryRow.swift, Composer/CreateSheet.swift, ParalistShare/*, ParalistWidgets/*
import ParalistCore
import SwiftUI

struct TypeLook {
    let color: Color
    let icon: TabIcon
    let label: String
    let hint: String

    static func of(_ entry: Entry) -> TypeLook {
        let base = of(entry.type)
        if entry.type == .bookmark, let url = entry.url, let brand = LinkBrand.color(url) {
            return TypeLook(color: Palette.fixed(brand), icon: base.icon, label: base.label, hint: base.hint)
        }
        if entry.type == .tag {
            return TypeLook(color: base.color, icon: TagKindLook.of(entry.tagKind).icon, label: base.label, hint: base.hint)
        }
        guard entry.type == .file || entry.type == .document, let attachment = entry.attachment else { return base }
        switch FileCategory.of(attachment) {
        case .photo: return TypeLook(color: Palette.mediaPhoto, icon: AppIcons.filePhoto, label: "create_photo", hint: base.hint)
        case .video: return TypeLook(color: Palette.mediaVideo, icon: AppIcons.fileVideo, label: "create_video", hint: base.hint)
        case .audio: return TypeLook(color: Palette.mediaAudio, icon: AppIcons.fileAudio, label: "create_audio", hint: base.hint)
        case .pdf: return TypeLook(color: Palette.mediaPdf, icon: AppIcons.filePdf, label: base.label, hint: base.hint)
        case .markdown: return TypeLook(color: Palette.mediaMarkdown, icon: AppIcons.fileMarkdown, label: base.label, hint: base.hint)
        case .text: return TypeLook(color: Palette.mediaDocument, icon: AppIcons.fileText, label: base.label, hint: base.hint)
        case .other: return TypeLook(color: Palette.mediaDocument, icon: base.icon, label: base.label, hint: base.hint)
        }
    }

    static func inList(_ entry: Entry) -> TypeLook {
        let look = of(entry)
        guard entry.type == .bookmark else { return look }
        return TypeLook(color: of(.bookmark).color, icon: look.icon, label: look.label, hint: look.hint)
    }

    static func of(_ type: EntryType) -> TypeLook {
        switch type {
        case .note: return TypeLook(color: Palette.fixed(0xFBBF24), icon: AppIcons.note, label: "type_note", hint: "composer_hint_note")
        case .task: return TypeLook(color: Palette.fixed(0x0B8CE9), icon: AppIcons.task, label: "type_task", hint: "composer_hint_task")
        case .event: return TypeLook(color: Palette.fixed(0x35C7E8), icon: AppIcons.calendar, label: "type_event", hint: "composer_hint_event")
        case .project: return TypeLook(color: Palette.fixed(0xE03E3E), icon: AppIcons.project, label: "type_project", hint: "composer_hint_project")
        case .area: return TypeLook(color: Palette.fixed(0xD09020), icon: AppIcons.area, label: "type_area", hint: "composer_hint_area")
        case .bookmark: return TypeLook(color: Palette.fixed(0x7C3AED), icon: AppIcons.bookmark, label: "type_bookmark", hint: "composer_hint_bookmark")
        case .file: return TypeLook(color: Palette.fixed(0x10B981), icon: AppIcons.file, label: "type_file", hint: "composer_hint_file")
        case .document: return TypeLook(color: Palette.fixed(0x1E4FD0), icon: AppIcons.document, label: "type_document", hint: "composer_hint_document")
        case .flashcard: return TypeLook(color: Palette.fixed(0xD97706), icon: AppIcons.flashcards, label: "type_flashcard", hint: "composer_hint_flashcard")
        case .deck: return TypeLook(color: Palette.fixed(0xB45309), icon: AppIcons.deck, label: "type_deck", hint: "composer_hint_deck")
        case .tag: return TypeLook(color: Palette.fixed(0xDB2777), icon: AppIcons.tag, label: "type_tag", hint: "composer_hint_tag")
        }
    }
}

struct TagKindLook {
    let icon: TabIcon
    let label: String

    static func of(_ kind: TagKind?) -> TagKindLook {
        switch kind {
        case .person: return TagKindLook(icon: AppIcons.person, label: "tag_kind_person")
        case .place: return TagKindLook(icon: AppIcons.tagPlace, label: "tag_kind_place")
        default: return TagKindLook(icon: AppIcons.tag, label: "tag_kind_tag")
        }
    }
}

struct StatusLook {
    let icon: String
    let label: String
    let color: Color
    let onColor: Color

    static func of(_ status: TaskStatus?, for type: EntryType = .task) -> StatusLook {
        let label = status.map { EntryStatus.label($0, for: type) } ?? "status_open"
        switch status {
        case .done, .read, .viewed, .listened, .played, .learned:
            return StatusLook(icon: AppIcons.task.filled, label: label, color: Palette.done, onColor: Palette.onDone)
        case .inProgress:
            return StatusLook(icon: "circle.lefthalf.filled", label: label, color: Palette.inProgress, onColor: Palette.onInProgress)
        case .postponed:
            return StatusLook(icon: "arrow.uturn.forward.circle", label: label, color: Palette.reviewed, onColor: Palette.onInProgress)
        case .cancelled:
            return StatusLook(icon: "xmark.circle", label: label, color: Palette.error, onColor: Palette.onInProgress)
        case .closed:
            return StatusLook(icon: "lock.circle", label: label, color: Palette.openTask, onColor: Palette.onOpenTask)
        case .shared:
            return StatusLook(icon: "arrowshape.turn.up.right.circle", label: label, color: Palette.inProgress, onColor: Palette.onInProgress)
        case .hard:
            return StatusLook(icon: "flame.circle", label: label, color: Palette.error, onColor: Palette.onInProgress)
        case .good:
            return StatusLook(icon: "hand.thumbsup.circle", label: label, color: Palette.inProgress, onColor: Palette.onInProgress)
        case .easy:
            return StatusLook(icon: "sparkles", label: label, color: Palette.done, onColor: Palette.onDone)
        default:
            return StatusLook(icon: AppIcons.circle, label: label, color: Palette.openTask, onColor: Palette.onOpenTask)
        }
    }
}

enum ListTitles {
    static func of(_ kind: ListKind) -> String {
        switch kind {
        case .inbox: return L.s("list_inbox")
        case .marked: return L.s("tab_marked")
        case .pinned: return L.s("list_pinned")
        case .favorites: return L.s("list_favorites")
        case .all: return L.s("list_all")
        case .archive: return L.s("tile_archive")
        case .projects: return L.s("tile_projects")
        case .areas: return L.s("tile_areas")
        case .resources: return L.s("tile_resources")
        case .notes: return L.s("list_notes")
        case .tasks: return L.s("list_tasks")
        case .events: return L.s("list_events")
        case .bookmarks: return L.s("list_bookmarks")
        case .files: return L.s("list_files")
        case .tags: return L.s("list_tags")
        case .flashcards: return L.s("list_flashcards")
        }
    }

    static func icon(_ kind: ListKind) -> String {
        switch kind {
        case .inbox: return AppIcons.inbox
        case .marked: return AppIcons.favorite.filled
        case .pinned: return AppIcons.pin.outlined
        case .favorites: return AppIcons.favorite.outlined
        case .all: return AppIcons.overview.outlined
        case .archive: return AppIcons.archive
        case .projects: return AppIcons.project.outlined
        case .areas: return AppIcons.area.outlined
        case .resources: return AppIcons.resources
        case .notes: return AppIcons.note.outlined
        case .tasks: return AppIcons.task.outlined
        case .events: return AppIcons.calendar.outlined
        case .bookmarks: return AppIcons.bookmark.outlined
        case .files: return AppIcons.file.outlined
        case .tags: return AppIcons.tag.outlined
        case .flashcards: return AppIcons.flashcards.outlined
        }
    }

    static func of(_ tab: LinkTab) -> String {
        switch tab {
        case .projects: return of(ListKind.projects)
        case .areas: return of(ListKind.areas)
        case .tasks: return of(ListKind.tasks)
        case .notes: return of(ListKind.notes)
        case .events: return of(ListKind.events)
        case .resources: return of(ListKind.resources)
        case .decks: return L.s("list_decks")
        case .flashcards: return of(ListKind.flashcards)
        case .tags: return of(ListKind.tags)
        }
    }

    static func new(_ type: EntryType) -> String {
        switch type {
        case .area: return L.s("add_new_area")
        case .project: return L.s("add_new_project")
        case .tag: return L.s("add_new_tag")
        case .task: return L.s("add_new_task")
        case .deck: return L.s("composer_hint_deck")
        case .flashcard: return L.s("add_new_flashcard")
        default: return L.s("add_new_note")
        }
    }

    static func icon(_ tab: LinkTab) -> String {
        switch tab {
        case .projects: return icon(ListKind.projects)
        case .areas: return icon(ListKind.areas)
        case .tasks: return icon(ListKind.tasks)
        case .notes: return icon(ListKind.notes)
        case .events: return icon(ListKind.events)
        case .resources: return icon(ListKind.resources)
        case .decks: return AppIcons.deck.outlined
        case .flashcards: return icon(ListKind.flashcards)
        case .tags: return icon(ListKind.tags)
        }
    }

    static func empty(_ kind: ListKind) -> String {
        switch kind {
        case .marked: return L.s("empty_marked")
        case .pinned: return L.s("empty_kind_pinned")
        case .favorites: return L.s("empty_kind_favorites")
        case .inbox: return L.s("empty_kind_inbox")
        case .all: return L.s("empty_kind_all")
        case .archive: return L.s("empty_kind_archive")
        case .projects: return L.s("empty_kind_projects")
        case .areas: return L.s("empty_kind_areas")
        case .resources: return L.s("empty_kind_resources")
        case .notes: return L.s("empty_kind_notes")
        case .tasks: return L.s("empty_kind_tasks")
        case .events: return L.s("empty_kind_events")
        case .bookmarks: return L.s("empty_kind_bookmarks")
        case .files: return L.s("empty_kind_files")
        case .tags: return L.s("empty_kind_tags")
        case .flashcards: return L.s("empty_kind_flashcards")
        }
    }
}
