// Zusammenhang: Search/SearchView.swift, ParalistCore Library/SearchHome.swift
import ParalistCore
import SwiftUI

struct SearchHomeTabs: View {
    @Binding var selection: SearchHome
    @Namespace private var namespace

    var body: some View {
        ViewThatFits(in: .horizontal) {
            pills(fill: true)
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    pills(fill: false)
                }
                .scrollIndicators(.hidden)
                .clipShape(Capsule())
                .onAppear { proxy.scrollTo(selection, anchor: .center) }
                .onChange(of: selection) { _, tab in
                    withAnimation(Motion.short) { proxy.scrollTo(tab, anchor: .center) }
                }
            }
        }
        .padding(4)
        .frame(height: 44)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, Dimens.pageEdge)
        .padding(.vertical, 6)
    }

    private func pills(fill: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(SearchHome.allCases, id: \.self) { tab in
                Button {
                    withAnimation(Motion.short) { selection = tab }
                } label: {
                    Text(L.s(tab.key))
                        .font(Typo.dm(14, .medium))
                        .foregroundStyle(selection == tab ? Palette.tabTextActive : Palette.muted)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 16)
                        .frame(maxWidth: fill ? .infinity : nil, minHeight: 36)
                        .background {
                            if selection == tab {
                                Capsule().fill(Palette.tabActive).matchedGeometryEffect(id: "homeTab", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .id(tab)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
    }
}
