// Zusammenhang: Entry/CoverStage.swift, Entry/CoverVideo.swift (CoverPlayButton), Entry/EntryPage.swift, Theme/Dimens.swift (cover*), Theme/Palette.swift
import ParalistCore
import SwiftUI

struct CoverChrome: View {
    let entry: Entry
    let playing: Bool
    let hasPlay: Bool
    let trailing: CGFloat
    let onPlay: () -> Void
    let onToggleDone: () -> Void
    @Binding var frame: CGRect
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        titleLine
            .padding(.leading, Dimens.coverRowInset)
            .padding(.trailing, Dimens.coverRowInset + trailing)
            .padding(.vertical, Dimens.coverRowInset)
            .background {
                LinearGradient(
                    stops: [
                        .init(color: Palette.surfaceContainer.opacity(0), location: 0),
                        .init(color: Palette.surfaceContainer.opacity(0.7), location: 0.45),
                        .init(color: Palette.surfaceContainer.opacity(0.94), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .padding(.top, Dimens.coverRowInset - Dimens.coverFadeLead)
                .allowsHitTesting(false)
            }
            .environment(\.colorScheme, playing ? .dark : scheme)
            .animation(Motion.dock, value: trailing)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }

    private var titleLine: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                .font(Typo.headlineMedium)
                .foregroundStyle(entry.title.isEmpty ? Palette.muted : Palette.onSurface)
                .lineLimit(Dimens.coverTitleLines)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if entry.type == .task || entry.type == .project {
                Button(action: onToggleDone) {
                    Image(systemName: entry.isDone ? AppIcons.task.filled : AppIcons.circle)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(entry.isDone ? Palette.done : Palette.openTask)
                        .frame(width: Dimens.coverPlay, height: Dimens.coverPlay)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: entry.isDone) { _, now in now }
                .accessibilityLabel(L.s(entry.isDone ? "task_mark_open" : "task_mark_done"))
            }
            if hasPlay {
                CoverPlayButton(playing: playing, action: onPlay)
            }
        }
    }
}
