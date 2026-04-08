// Color+Extensions.swift
// gerisayimpro

import SwiftUI

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6 else { return nil }
        var val: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&val) else { return nil }
        self.init(.sRGB,
                  red:   Double((val & 0xFF0000) >> 16) / 255,
                  green: Double((val & 0x00FF00) >>  8) / 255,
                  blue:  Double( val & 0x0000FF)         / 255)
    }
}
