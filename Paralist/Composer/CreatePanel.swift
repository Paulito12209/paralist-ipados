// Zusammenhang: Shell/CreateOverlay.swift, Capture/CaptureKind.swift, Theme/Palette.swift, Entries/TypeLook.swift, Icons/XoolIcons.swift, Composer/ComposerSheet.swift
import ParalistCore
import SwiftUI

struct CreatePanel: View {
    let onCapture: (CaptureKind) -> Void
    let onPick: (EntryType) -> Void

    private let sections: [(String, [EntryType])] = [
        ("section_resources", [.bookmark, .document]),
        ("section_organize", [.tag, .project, .area]),
        ("section_quick", [.event, .note, .task]),
        ("section_learn", [.deck, .flashcard]),
    ]

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }.scrollBounceBehavior(.basedOnSize)
        }
        .background { CreateBackdrop() }
        .clipShape(RoundedRectangle(cornerRadius: CreateDimens.panelRadius, style: .continuous))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Palette.onSurface.opacity(0.3))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CreateDimens.tileGap) {
                    ForEach(CaptureKind.allCases) { kind in CaptureTile(kind: kind) { onCapture(kind) } }
                }
                .padding(.horizontal, 16)
            }
            ForEach(sections, id: \.0) { section in
                Text(L.s(section.0))
                    .font(Typo.labelMedium)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 8)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(section.1, id: \.self) { type in TypeChip(type: type) { onPick(type) } }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, CreateDimens.homeIndicator)
    }
}

struct CreateBackdrop: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(colors: [Palette.sheetTop, Palette.sheetBottom], startPoint: .top, endPoint: .bottom).opacity(CreateDimens.sheetOpacity)
            RadialGradient(colors: [Palette.sheetGlow.opacity(0.18), .clear], center: .top, startRadius: 0, endRadius: 320)
            RadialGradient(colors: [Palette.sheetGlow.opacity(0.12), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 260)
        }
    }
}

struct CaptureTile: View {
    let kind: CaptureKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: kind.icon).font(.system(size: 21, weight: .regular)).frame(height: 26)
                Text(L.s(kind.label)).font(Typo.dm(14, .medium))
            }
            .foregroundStyle(Palette.onSurface)
            .frame(width: CreateDimens.tileWidth, height: CreateDimens.tileHeight)
            .background(Palette.chipFill.opacity(0.5), in: RoundedRectangle(cornerRadius: CreateDimens.tileRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CreateDimens.tileRadius, style: .continuous).stroke(Palette.onSurface.opacity(0.1), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: CreateDimens.tileRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TypeChip: View {
    let type: EntryType
    let action: () -> Void

    var body: some View {
        let look = TypeLook.of(type)
        Button(action: action) {
            HStack(spacing: 7) {
                GlyphIcon(look.icon.outlined, size: 15).foregroundStyle(look.color)
                Text(L.s(look.label)).font(Typo.dm(13, .medium)).foregroundStyle(Palette.onSurface)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Palette.chipFill.opacity(0.5), in: Capsule())
            .overlay(Capsule().stroke(Palette.onSurface.opacity(0.1), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
