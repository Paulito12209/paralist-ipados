// Zusammenhang: Shell/SectionChrome.swift, Account/AvatarStore.swift, ParalistCore Planning/XpLog.swift
import ParalistCore
import SwiftUI

struct LevelRing: View {
    let info: LevelInfo
    let name: String
    let stamp: Double
    var size: CGFloat = Dimens.levelRing

    var body: some View {
        let stroke: CGFloat = 2.8
        ZStack {
            Circle().stroke(Palette.outlineVariant, lineWidth: stroke)
            Circle().trim(from: 0, to: info.progress)
                .stroke(Palette.level, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            AvatarDisc(name: name, stamp: stamp, iconSize: 16, initialSize: 13)
                .frame(width: size - stroke * 2 - 4, height: size - stroke * 2 - 4)
        }
        .padding(stroke / 2)
        .frame(width: size, height: size)
        .overlay(alignment: .bottom) {
            Text("\(info.level)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.level)
                .padding(.horizontal, 4)
                .background(Palette.background, in: Capsule())
                .offset(y: 5)
        }
    }
}

struct AvatarDisc: View {
    let name: String
    let stamp: Double
    var iconSize: CGFloat = 20
    var initialSize: CGFloat = 15

    var body: some View {
        ZStack {
            Circle().fill(Palette.primaryContainer)
            if stamp > 0, let image = AvatarStore.load(stamp: stamp) {
                Image(uiImage: image).resizable().scaledToFill().clipShape(Circle())
            } else if let initial = name.trimmingCharacters(in: .whitespaces).first {
                Text(String(initial).uppercased()).font(.system(size: initialSize, weight: .semibold)).foregroundStyle(Palette.onPrimaryContainer)
            } else {
                Image(systemName: AppIcons.person.filled).font(.system(size: iconSize)).foregroundStyle(Palette.onPrimaryContainer)
            }
        }
        .clipShape(Circle())
    }
}
