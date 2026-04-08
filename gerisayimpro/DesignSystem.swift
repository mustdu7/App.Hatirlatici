// DesignSystem.swift
// gerisayimpro

import SwiftUI

// MARK: - Renkler

extension Color {
    static let appBackground = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let appSurface    = Color(red: 0.078, green: 0.078, blue: 0.078)
    static let appBorder     = Color(red: 0.122, green: 0.122, blue: 0.122)
    static let appPrimary    = Color(red: 0.941, green: 0.929, blue: 0.910)
}

// MARK: - Kart Modifier

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.appBorder, lineWidth: 0.5))
    }
}

extension View {
    func appCard() -> some View { modifier(AppCardModifier()) }
}

// MARK: - Segment Seçici

struct AppSegmentedPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [(label: String, value: T)]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let opt = options[i]
                let sel = selection == opt.value
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = opt.value }
                } label: {
                    Text(opt.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(sel ? Color.appBackground : Color.appPrimary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(sel ? Color.appPrimary : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.appBorder, lineWidth: 0.5))
    }
}

// MARK: - Sabitler

enum AppSpacing {
    static let cardGap:       CGFloat = 10
    static let cardPadding:   CGFloat = 20
    static let fabSize:       CGFloat = 56
    static let fabMargin:     CGFloat = 24
    static let smallRadius:   CGFloat = 14
    static let cardRadius:    CGFloat = 20
    static let screenPadding: CGFloat = 16
}

enum AppFont {
    static func cardNumber() -> Font { .system(size: 32, weight: .bold) }
    static func body()       -> Font { .system(size: 16, weight: .regular) }
    static func secondary()  -> Font { .system(size: 13, weight: .regular) }
    static func label(_ weight: Font.Weight = .bold) -> Font { .system(size: 16, weight: weight) }
}
