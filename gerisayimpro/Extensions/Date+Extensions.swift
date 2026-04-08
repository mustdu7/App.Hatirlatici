// Date+Extensions.swift
// gerisayimpro

import Foundation

extension Calendar {
    func daysUntil(_ date: Date) -> Int {
        let start = startOfDay(for: Date())
        let end   = startOfDay(for: date)
        return dateComponents([.day], from: start, to: end).day ?? 0
    }
}

extension TimeInterval {
    var offsetLabel: String {
        let s = Int(self)
        if s == 0       { return "Etkinlik anında"    }
        if s < 3_600    { return "\(s/60) dakika önce"  }
        if s < 86_400   { return "\(s/3_600) saat önce" }
        if s < 604_800  { return "\(s/86_400) gün önce" }
        return "\(s/604_800) hafta önce"
    }
}
