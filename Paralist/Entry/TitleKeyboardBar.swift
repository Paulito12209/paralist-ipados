// Zusammenhang: Entry/EntryTitle.swift, Entry/EntryBodyEditor.swift, Entry/EntryPage.swift, Icons/AppIcons.swift, Theme/Palette.swift, Theme/Dimens.swift
import SwiftUI

struct TitleBarActions {
    let copy: () -> Void
    let rewrite: () -> Void
    let restore: (() -> Void)?
    let close: () -> Void
}

struct TitleKeyboardBar: View {
    let actions: TitleBarActions
    private let height: CGFloat = 36

    var body: some View {
        HStack(spacing: 8) {
            pill("entry_title_copy", icon: AppIcons.copy, action: actions.copy)
            if let restore = actions.restore {
                pill("entry_title_restore", icon: AppIcons.restoreTitle, action: restore)
            } else {
                pill("entry_title_rewrite", icon: AppIcons.rewriteTitle, action: actions.rewrite)
            }
            Button(action: actions.close) {
                Image(systemName: AppIcons.hideKeyboard).font(.system(size: 17, weight: .medium)).frame(width: height, height: height)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(L.s("entry_keyboard_hide"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .foregroundStyle(Palette.onSurface)
        .contentShape(Rectangle())
        .onTapGesture(perform: actions.close)
    }

    private func pill(_ key: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(L.s(key)).lineLimit(1).truncationMode(.tail)
            }
            .font(Typo.bodyMedium)
            .frame(maxWidth: .infinity, minHeight: height)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}

struct BodyBarActions {
    let undo: (() -> Void)?
    let deleteWord: () -> Void
    let close: () -> Void
}

struct BodyKeyboardBar: View {
    let actions: BodyBarActions
    private let height: CGFloat = 36

    var body: some View {
        HStack(spacing: 8) {
            if let undo = actions.undo {
                pill("entry_undo", icon: AppIcons.undo, action: undo)
            }
            pill("entry_delete_word", icon: AppIcons.deleteWord, action: actions.deleteWord)
            Spacer(minLength: 0)
            Button(action: actions.close) {
                Image(systemName: AppIcons.hideKeyboard).font(.system(size: 17, weight: .medium)).frame(width: height, height: height)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(L.s("entry_keyboard_hide"))
        }
        .padding(.horizontal, 16)
        .padding(.top, Dimens.caretGap)
        .padding(.bottom, 8)
        .foregroundStyle(Palette.onSurface)
    }

    private func pill(_ key: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(L.s(key)).lineLimit(1)
            }
            .font(Typo.bodyMedium)
            .frame(minHeight: height)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}
