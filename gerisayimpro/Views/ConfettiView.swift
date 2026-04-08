// ConfettiView.swift
// gerisayimpro
//
// Tüm yaklaşan etkinlikler tamamlandığında gösterilen konfeti animasyonu.

import SwiftUI

// MARK: - ConfettiView

struct ConfettiView: View {

    private struct Piece: Identifiable {
        let id       = UUID()
        let x:        CGFloat
        let delay:    Double
        let size:     CGFloat
        let opacity:  Double
        let angle:    Double
        let spin:     Double
        let duration: Double
    }

    private let pieces: [Piece] = (0..<70).map { _ in
        Piece(
            x:        CGFloat.random(in: 0...1),
            delay:    Double.random(in: 0...1.8),
            size:     CGFloat.random(in: 5...14),
            opacity:  Double.random(in: 0.3...0.9),
            angle:    Double.random(in: 0...360),
            spin:     Double.random(in: 1...4) * (Bool.random() ? 1 : -1),
            duration: Double.random(in: 1.6...2.8)
        )
    }

    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appPrimary.opacity(p.opacity))
                    .frame(width: p.size, height: p.size * 0.45)
                    .rotationEffect(.degrees(p.angle + (fallen ? p.spin * 360 : 0)))
                    .position(
                        x: p.x * geo.size.width,
                        y: fallen ? geo.size.height + 30 : -20
                    )
                    .animation(
                        .easeIn(duration: p.duration).delay(p.delay),
                        value: fallen
                    )
            }
        }
        .onAppear {
            fallen = true
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ConfettiView()
    }
    .preferredColorScheme(.dark)
}
