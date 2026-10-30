// Zusammenhang: Pages/FolderStage.swift (FolderStage, PinnedCardShell), Pages/TaskFolder.swift, Pages/TasksPage.swift, Entries/TypeLook.swift (StatusLook), App/AppModel.swift (setStatus), Theme/FolderTone.swift (folderTone), Theme/Dimens.swift (TaskDimens), ParalistCore Library/TaskView.swift
import ParalistCore
import SwiftUI

struct TaskStage: View {
    let activeCount: Int
    let archivedCount: Int
    let pinned: Entry?
    @Binding var archive: Bool
    @Binding var showsPin: Bool
    let onOpen: (Entry) -> Void

    var body: some View {
        FolderStage(pinKey: pinned?.id, showsPin: $showsPin) {
            TaskFolder(count: archive ? archivedCount : activeCount, archive: $archive)
        } card: { allowed in
            if let pinned { TaskPinnedCard(entry: pinned) { if allowed() { onOpen(pinned) } } }
        }
    }
}

struct TaskPinnedCard: View {
    let entry: Entry
    let onOpen: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.folderTone) private var tone

    var body: some View {
        PinnedCardShell(glyph: AppIcons.task.outlined, tint: TypeLook.of(.task).color,
                        title: entry.title.isEmpty ? L.s("list_untitled") : entry.title,
                        openLabel: L.s("tasks_pinned_open"), onOpen: onOpen) {
            statusPill(StatusLook.of(entry.status))
        }
    }

    private func statusPill(_ status: StatusLook) -> some View {
        Menu {
            ForEach(TaskViewSetting.statuses, id: \.self) { option in
                Button { model.setStatus(entry.id, option) } label: {
                    Label(L.s(StatusLook.of(option).label), systemImage: StatusLook.of(option).icon)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: status.icon).font(.system(size: 16)).foregroundStyle(status.color)
                Text(L.s(status.label)).font(Typo.dm(15, .medium)).foregroundStyle(tone.ink).lineLimit(1)
                Image(systemName: AppIcons.expandMore).font(.system(size: 11, weight: .semibold)).foregroundStyle(tone.inkMuted)
            }
            .padding(.horizontal, 14)
            .frame(height: TaskDimens.pillHeight)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}
