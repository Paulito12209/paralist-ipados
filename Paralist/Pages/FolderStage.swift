// Zusammenhang: Pages/TaskStage.swift (Aufgaben), Pages/SectionStage.swift (Sammlungen, Chats), Pages/TaskFolder.swift (Ordner, TaskGlowBackdrop), Theme/Dimens.swift (TaskDimens), Theme/FolderTone.swift (folderTone)
import SwiftUI

struct FolderStage<Folder: View, Card: View>: View {
    let pinKey: String?
    @Binding var showsPin: Bool
    @ViewBuilder let folder: () -> Folder
    @ViewBuilder let card: (@escaping () -> Bool) -> Card
    @State private var drag: CGFloat = 0
    @State private var draggedAt = Date.distantPast

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let gap = TaskDimens.folderTrail - TaskDimens.pinPeek
            let folderWidth = max(w - TaskDimens.folderLead - TaskDimens.folderTrail, 0)
            let cardWidth = max(w - TaskDimens.restPeek - gap - TaskDimens.folderTrail, 0)
            let shift = TaskDimens.folderLead + folderWidth - TaskDimens.restPeek
            let front = pinKey != nil && showsPin
            HStack(alignment: .center, spacing: gap) {
                folder()
                    .frame(width: folderWidth, height: front ? TaskDimens.restHeight : TaskDimens.folderHeight)
                if pinKey != nil {
                    card { Date.now.timeIntervalSince(draggedAt) > MenuDimens.tapLock }
                        .frame(width: cardWidth, height: front ? TaskDimens.folderHeight : TaskDimens.restHeight)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.leading, TaskDimens.folderLead)
            .frame(width: w, height: TaskDimens.folderHeight, alignment: .leading)
            .offset(x: (front ? -shift : 0) + drag)
            .contentShape(Rectangle())
            .simultaneousGesture(pinKey == nil ? nil : swipe(shift: shift))
            .animation(Motion.dock, value: front)
            .animation(Motion.dock, value: pinKey)
        }
        .frame(height: TaskDimens.folderHeight)
        .padding(.bottom, TaskDimens.stageBottom)
        .onChange(of: pinKey) { _, now in if now == nil { showsPin = false } }
    }

    private func swipe(shift: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: SwipeDimens.slop)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                draggedAt = .now
                let raw = value.translation.width
                let limit = showsPin ? shift : 0
                drag = showsPin ? min(max(raw, -limit * 0.15), shift) : max(min(raw, shift * 0.15), -shift)
            }
            .onEnded { value in
                guard drag != 0 else { return }
                draggedAt = .now
                let moved = value.predictedEndTranslation.width
                withAnimation(Motion.dock) {
                    if !showsPin, moved < -TaskDimens.swipeTrigger { showsPin = true }
                    else if showsPin, moved > TaskDimens.swipeTrigger { showsPin = false }
                    drag = 0
                }
            }
    }
}

struct PinnedCardShell<Footer: View>: View {
    let glyph: String
    let tint: Color
    let title: String
    let openLabel: String
    let onOpen: () -> Void
    @ViewBuilder let footer: () -> Footer
    @Environment(\.folderTone) private var tone

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: TaskDimens.pinRadius, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                GlyphIcon(glyph, size: TaskDimens.pinGlyph, weight: .light)
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.5), radius: 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button(action: onOpen) {
                    Image(systemName: AppIcons.openArrow)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tone.ink)
                        .frame(width: TaskDimens.iconCircle, height: TaskDimens.iconCircle)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(openLabel)
            }
            .frame(maxHeight: .infinity)
            Text(title)
                .font(Typo.dm(16, .medium))
                .foregroundStyle(tone.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            HStack(alignment: .center) {
                Image(systemName: AppIcons.pin.filled)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tone.inkMuted)
                    .frame(width: TaskDimens.iconCircle, height: TaskDimens.iconCircle)
                    .glassEffect(.regular, in: Circle())
                Spacer(minLength: 0)
                footer()
            }
        }
        .padding(TaskDimens.pinPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background { TaskGlowBackdrop() }
        .clipShape(shape)
        .overlay(shape.stroke(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .shadow(color: tone.glowDeep.opacity(0.16), radius: 14, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

struct FolderPill: View {
    let text: String
    @Environment(\.folderTone) private var tone

    var body: some View {
        Text(text).font(Typo.dm(15, .medium)).foregroundStyle(tone.ink).lineLimit(1)
            .padding(.horizontal, 14)
            .frame(height: TaskDimens.pillHeight)
            .glassEffect(.regular, in: Capsule())
    }
}
