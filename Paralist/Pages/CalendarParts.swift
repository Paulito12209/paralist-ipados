// Zusammenhang: Pages/CalendarPage.swift, Pages/CalendarStripRow.swift, Pages/CalendarCollapse.swift, ParalistCore Planning/NestedCollapse.swift, ParalistCore Planning/WeekGrid.swift, ParalistCore Planning/CalendarLayout.swift, Entries/TypeLook.swift, Shell/Router.swift (tabBarLift), Theme/Palette.swift (calendarGrid)
import ParalistCore
import SwiftUI

struct CalendarGrid: View {
    let days: [Day]
    let today: Day
    let rows: [Entry]
    let onCreate: (Day, Int) -> Void
    let onOpen: (String) -> Void
    var onScroll: (ScrollSpot, Bool) -> Void = { _, _ in }
    var onSwipe: (Int) -> Void = { _ in }
    var collapse: CGFloat = 0
    var collapseLimit: CGFloat = 0
    var onCollapse: (CGFloat) -> Void = { _ in }
    var onSettle: () -> Void = {}
    @Environment(Router.self) private var router
    @Environment(\.tabRoot) private var tabRoot
    @State private var armed = false
    @State private var position = ScrollPosition()
    @State private var swipedAt = Date.distantPast
    @State private var stripHeight: CGFloat = 0

    private struct Placed: Identifiable {
        let entry: Entry
        let block: TimedBlock
        let column: Int
        var id: String { "\(column)-\(block.id)" }
    }

    var body: some View {
        let timed = rows.filter { !$0.allDay && $0.start != nil }
        let placed = days.enumerated().flatMap { column, day in
            timed.compactMap { e in
                WeekGrid.blockFor(id: e.id, start: e.start!, end: e.end, day: day, zone: .current).map { Placed(entry: e, block: $0, column: column) }
            }
        }
        VStack(spacing: 0) {
            CalendarStripRow(days: days, rows: rows, onOpen: { if tapAllowed { onOpen($0) } })
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stripHeight = $0 }
            ScrollView {
                timeline(placed)
                    .frame(height: Dimens.hourHeight * 24)
                    .padding(.trailing, Dimens.calendarTrail)
                    .background(alignment: .topLeading) {
                        HStack(spacing: 0) {
                            Color.clear.frame(width: Dimens.calendarGutter)
                            RoundedRectangle(cornerRadius: Dimens.calendarGridRadius).fill(Palette.calendarGrid)
                            Color.clear.frame(width: Dimens.calendarTrail)
                        }
                    }
                    .background { CalendarCollapse(collapse: collapse, limit: collapseLimit, onCollapse: onCollapse) }
                    .padding(.bottom, tabRoot ? Dimens.calendarTail(lift: router.tabBarLift) : Dimens.stripGap)
            }
            .scrollPosition($position)
            .onScrollGeometryChange(for: ScrollSpot.self) { geo in
                ScrollSpot(y: geo.contentOffset.y + geo.contentInsets.top,
                           max: geo.contentSize.height + geo.contentInsets.top + geo.contentInsets.bottom - geo.containerSize.height)
            } action: { _, spot in onScroll(spot, armed) }
            .onScrollPhaseChange { _, phase in
                if phase == .idle { onSettle() }
            }
            .onAppear {
                let now = days.contains(today) ? WeekGrid.nowMinute(Date(), zone: .current, day: today) : nil
                let anchor = now ?? placed.map(\.block.startMinute).min() ?? Dimens.calendarStartMinute
                position.scrollTo(y: NestedCollapse.startOffset(anchorMinute: anchor, hourHeight: Dimens.hourHeight))
                Task { @MainActor in armed = true }
            }
        }
        .simultaneousGesture(swipe)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10).onChanged { value in
            guard swipes(value) else { return }
            swipedAt = .now
        }
        .onEnded { value in
            guard swipes(value), abs(value.translation.width) > abs(value.translation.height) * 1.5, abs(value.translation.width) > 60 else { return }
            onSwipe(value.translation.width < 0 ? 1 : -1)
        }
    }

    private func swipes(_ value: DragGesture.Value) -> Bool {
        days.count > 1 || value.startLocation.y > stripHeight
    }

    private var tapAllowed: Bool {
        Date.now.timeIntervalSince(swipedAt) > MenuDimens.tapLock
    }

    private func timeline(_ placed: [Placed]) -> some View {
        GeometryReader { geo in
            let column = (geo.size.width - Dimens.calendarGutter) / CGFloat(days.count)
            let gap: CGFloat = days.count == 1 ? 6 : Dimens.calendarBlockGap
            ZStack(alignment: .topLeading) {
                ForEach(1..<24, id: \.self) { hour in
                    hourLine(hour).offset(y: CGFloat(hour) * Dimens.hourHeight - Dimens.hourLabelHeight / 2)
                }
                if days.count > 1 {
                    ForEach(1..<days.count, id: \.self) { i in
                        Rectangle().fill(Palette.calendarLine).frame(width: Dimens.calendarColumnLine, height: geo.size.height)
                            .offset(x: Dimens.calendarGutter + CGFloat(i) * column)
                    }
                }
                ForEach(placed) { item in
                    block(item.entry, item.block, compact: days.count > 1)
                        .frame(width: max(column - gap * 2, 20),
                               height: CGFloat(item.block.endMinute - item.block.startMinute) / 60 * Dimens.hourHeight - Dimens.calendarBlockGap)
                        .offset(x: Dimens.calendarGutter + CGFloat(item.column) * column + gap,
                                y: CGFloat(item.block.startMinute) / 60 * Dimens.hourHeight + 1)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    if let minute = WeekGrid.nowMinute(Date(), zone: .current, day: day) {
                        let x = Dimens.calendarGutter + CGFloat(i) * column
                        let y = CGFloat(minute) / 60 * Dimens.hourHeight
                        Rectangle().fill(Palette.primary).frame(width: column, height: 2)
                            .offset(x: x, y: y - 1)
                        Circle().fill(Palette.primary).frame(width: Dimens.nowDot, height: Dimens.nowDot)
                            .offset(x: x - Dimens.nowDot, y: y - Dimens.nowDot / 2)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard tapAllowed else { return }
                let hour = min(23, max(0, Int(location.y / Dimens.hourHeight)))
                let col = min(days.count - 1, max(0, Int((location.x - Dimens.calendarGutter) / column)))
                onCreate(days[col], hour)
            }
        }
    }

    private func hourLine(_ hour: Int) -> some View {
        HStack(spacing: 0) {
            Text(WeekGrid.hourLabel(hour)).font(Typo.labelSmall).foregroundStyle(Palette.muted)
                .frame(width: Dimens.weekLabelWidth, alignment: .leading)
                .padding(.leading, Dimens.pageEdge)
            DashLine()
                .stroke(Palette.calendarLine, style: StrokeStyle(lineWidth: Dimens.calendarLine, dash: [Dimens.calendarDash, Dimens.calendarDash]))
                .frame(height: Dimens.calendarLine)
        }
        .frame(height: Dimens.hourLabelHeight)
    }

    private func block(_ e: Entry, _ b: TimedBlock, compact: Bool) -> some View {
        let look = TypeLook.of(e.type)
        let title = e.title.isEmpty ? L.s("list_untitled") : e.title
        return Button { if tapAllowed { onOpen(e.id) } } label: {
            HStack(alignment: .top, spacing: 8) {
                if !compact { RoundedRectangle(cornerRadius: 2).fill(look.color).frame(width: 8, height: 8).padding(.top, 4) }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(compact ? Typo.labelSmall : Typo.bodyMedium).foregroundStyle(Palette.onSurface).lineLimit(compact ? 2 : 1)
                    if !compact, let s = e.start {
                        Text(WeekGrid.timeLabel(s, zone: .current) + " – " + WeekGrid.timeLabel(e.end ?? s.addingTimeInterval(3600), zone: .current))
                            .font(Typo.labelSmall).foregroundStyle(Palette.onSurfaceVariant)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, compact ? 6 : 10)
            .padding(.trailing, compact ? 3 : 10)
            .padding(.vertical, compact ? 2 : 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(look.color.opacity(0.18), in: RoundedRectangle(cornerRadius: compact ? 4 : 8))
            .overlay(alignment: .leading) {
                if compact { RoundedRectangle(cornerRadius: 1).fill(look.color).frame(width: 2).padding(.vertical, 2).padding(.leading, 1) }
            }
            .clipped()
        }
        .buttonStyle(.plain)
    }
}

struct DashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct ScrollSpot: Equatable {
    let y: CGFloat
    let max: CGFloat
}
