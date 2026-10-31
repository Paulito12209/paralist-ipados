// Zusammenhang: Icons/XoolIcons.swift, Entries/TypeLook.swift, Shell/*, Pages/*, ParalistShare/*, ParalistWidgets/*
import SwiftUI

struct TabIcon {
    let outlined: String
    let filled: String

    func resolve(_ active: Bool) -> String { active ? filled : outlined }
}

enum AppIcons {
    static let overview = TabIcon(outlined: "square.grid.2x2", filled: "square.grid.2x2.fill")
    static let calendar = TabIcon(outlined: "calendar", filled: "calendar")
    static let tasks = TabIcon(outlined: "checklist", filled: "checklist")
    static let media = TabIcon(outlined: "photo.on.rectangle", filled: "photo.fill.on.rectangle.fill")
    static let flashcards = TabIcon(outlined: "rectangle.on.rectangle.angled", filled: "rectangle.fill.on.rectangle.angled.fill")
    static let person = TabIcon(outlined: "person", filled: "person.fill")
    static let favorite = TabIcon(outlined: "star", filled: "star.fill")
    static let pin = TabIcon(outlined: "pin", filled: "pin.fill")
    static let note = TabIcon(outlined: "note.text", filled: "note.text")
    static let task = TabIcon(outlined: "checkmark.circle", filled: "checkmark.circle.fill")
    static let project = TabIcon(outlined: "asset:XoolRocket", filled: "asset:XoolRocket")
    static let area = TabIcon(outlined: "square.stack.3d.up", filled: "square.stack.3d.up.fill")
    static let bookmark = TabIcon(outlined: "bookmark", filled: "bookmark.fill")
    static let file = TabIcon(outlined: "doc", filled: "doc.fill")
    static let document = TabIcon(outlined: "doc.richtext", filled: "doc.richtext.fill")
    static let chat = TabIcon(outlined: "bubble.left.and.bubble.right", filled: "bubble.left.and.bubble.right.fill")
    static let deck = TabIcon(outlined: "rectangle.stack", filled: "rectangle.stack.fill")
    static let tag = TabIcon(outlined: "tag", filled: "tag.fill")
    static let tagPlace = TabIcon(outlined: "mappin.and.ellipse", filled: "mappin.and.ellipse")
    static let bell = TabIcon(outlined: "bell", filled: "bell.fill")
    static let menu = TabIcon(outlined: "line.3.horizontal", filled: "line.3.horizontal")
    static let filePhoto = TabIcon(outlined: "photo", filled: "photo.fill")
    static let fileVideo = TabIcon(outlined: "video", filled: "video.fill")
    static let fileAudio = TabIcon(outlined: "waveform", filled: "waveform")
    static let filePdf = TabIcon(outlined: "asset:MaterialPdf", filled: "asset:MaterialPdf")
    static let fileMarkdown = TabIcon(outlined: "asset:MaterialMarkdown", filled: "asset:MaterialMarkdown")
    static let fileText = TabIcon(outlined: "doc.text", filled: "doc.text.fill")

    static let assetPrefix = "asset:"

    static func assetName(_ name: String) -> String? {
        name.hasPrefix(assetPrefix) ? String(name.dropFirst(assetPrefix.count)) : nil
    }

    static func image(_ name: String) -> Image {
        assetName(name).map { Image($0).renderingMode(.template) } ?? Image(systemName: name)
    }

    static let add = "plus"
    static let stats = "chart.bar"
    static let addCircle = "asset:XoolAddCircle"
    static let school = "graduationcap"
    static let search = "magnifyingglass"
    static let clearField = "xmark.circle.fill"
    static let filter = "line.3.horizontal.decrease.circle"
    static let filterActive = "line.3.horizontal.decrease.circle.fill"
    static let sortBy = "arrow.up.arrow.down"
    static let sortDirection = "arrow.down.to.line"
    static let groupBy = "square.stack.3d.up"
    static let groupOrder = "arrow.up.and.down.text.horizontal"
    static let doneVisibility = "eye.circle"
    static let mic = "mic"
    static let camera = "camera"
    static let recordVideo = "video"
    static let stop = "stop.fill"
    static let briefing = "newspaper"
    static let language = "globe"
    static let darkMode = "moon"
    static let lightMode = "sun.max"
    static let edit = "pencil"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let calendarDay = "calendar.day.timeline.left"
    static let calendarWeek = "rectangle.split.3x1"
    static let calendarMonth = "square.grid.3x3"
    static let todayCheck = "checkmark"
    static let phone = "ipad"
    static let settings = "gearshape"
    static let refresh = "arrow.clockwise"
    static let close = "xmark"
    static let inbox = "tray"
    static let text = "text.alignleft"
    static let caret = "chevron.down"
    static let check = "checkmark"
    static let confirm = "checkmark.circle.fill"
    static let circle = "circle"
    static let event = "calendar.badge.clock"
    static let attach = "paperclip"
    static let archive = "archivebox"
    static let resources = "asset:XoolCube"
    static let more = "ellipsis"
    static let tabShown = "eye"
    static let tabHidden = "eye.slash"
    static let tabLabels = "textformat"
    static let openExternal = "arrow.up.right.square"
    static let openArrow = "arrow.up.right"
    static let openFile = "doc.text.magnifyingglass"
    static let importCards = "square.and.arrow.down"
    static let study = "graduationcap"
    static let canvasReturn = "chevron.left"
    static let fullscreen = "arrow.up.left.and.arrow.down.right"
    static let delete = "trash"
    static let toArchive = "archivebox"
    static let fromArchive = "arrow.uturn.backward"
    static let image = "photo"
    static let addImage = "photo.badge.plus"
    static let scanDocument = "doc.viewfinder"
    static let expandMore = "chevron.down"
    static let place = "tray.and.arrow.down"
    static let overviewTabs = "square.split.2x1"
    static let overviewStacked = "square.split.1x2"
    static let overviewSwitch = "rectangle.2.swap"
    static let schedule = "clock"
    static let link = "asset:StreamlineCodeBranch"
    static let copyLink = "link"
    static let copy = "doc.on.doc"
    static let undo = "arrow.uturn.backward"
    static let deleteWord = "delete.backward"
    static let hideKeyboard = "keyboard.chevron.compact.down"
    static let restoreTitle = "arrow.uturn.backward"
    static let rewriteTitle = "character.cursor.ibeam"
    static let palette = "paintpalette"
    static let lock = "lock"
    static let sparkle = "sparkles"
    static let feedback = "bubble.left.and.text.bubble.right"
    static let community = "person.3"
    static let download = "square.and.arrow.down"
    static let upload = "square.and.arrow.up"
    static let info = "info.circle"
    static let share = "square.and.arrow.up"
    static let views = "eye"
    static let shared = "arrowshape.turn.up.right"
    static let fileSize = "externaldrive"
    static let paste = "doc.on.clipboard"
    static let play = "play.fill"
    static let pause = "pause.fill"
    static let video = "play.rectangle"
    static let audio = "waveform"
    static let canvasActions = "hand.tap"
    static let canvasBack = "chevron.down"
    static let sidebarRight = "sidebar.right"
    static let suggestions = "sparkles"
    static let date = "calendar.badge.plus"
    static let dateSet = "calendar"
    static let openCanvas = "arrow.up.right"
    static let newChat = "square.and.pencil"
    static let send = "arrow.up"
    static let thinkingFast = "bolt"
    static let thinkingBalanced = "scalemass"
    static let thinkingThorough = "brain"
    static let rename = "pencil"
    static let warning = "exclamationmark.triangle"
}
