// AppIconDesigns.swift
// gerisayimpro

import SwiftUI

private let bg      = Color(red: 0.039, green: 0.039, blue: 0.039)
private let primary = Color(red: 0.941, green: 0.929, blue: 0.910)
private let iconSize: CGFloat = 1024

struct AppIcon_Arc: View {
    var body: some View {
        ZStack {
            bg

            Circle()
                .stroke(primary.opacity(0.06), lineWidth: 56)
                .frame(width: 720, height: 720)

            Circle()
                .trim(from: 0.083, to: 0.917)
                .stroke(primary, style: StrokeStyle(lineWidth: 52, lineCap: .round))
                .frame(width: 720, height: 720)
                .rotationEffect(.degrees(90))

            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 264) {
                    Circle().fill(primary).frame(width: 28, height: 28)
                    Circle().fill(primary).frame(width: 28, height: 28)
                }
                .padding(.bottom, 80)
            }
            .frame(width: iconSize, height: iconSize)

            Text("0")
                .font(.system(size: 380, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(primary)
                .offset(y: -16)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

#Preview {
    AppIcon_Arc()
        .frame(width: 320, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 70))
}
