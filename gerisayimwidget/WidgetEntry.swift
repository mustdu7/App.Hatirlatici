// WidgetEntry.swift
// gerisayimwidget

import WidgetKit
import Foundation

struct WidgetEvent {
    let id:         UUID
    let title:      String
    let targetDate: Date
    let icon:       String

    var daysRemaining: Int {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.startOfDay(for: targetDate)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isPast: Bool { targetDate < Date() }
    var isToday: Bool { Calendar.current.isDateInToday(targetDate) }
}

struct CountdownEntry: TimelineEntry {
    let date:        Date
    let event:       WidgetEvent?
    let secondEvent: WidgetEvent?

    static var placeholder: CountdownEntry {
        CountdownEntry(
            date: .now,
            event: WidgetEvent(
                id:         UUID(),
                title:      "Doğum Günü",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: .now)!,
                icon:       "gift"
            ),
            secondEvent: WidgetEvent(
                id:         UUID(),
                title:      "Tatil",
                targetDate: Calendar.current.date(byAdding: .day, value: 42, to: .now)!,
                icon:       "airplane"
            )
        )
    }
}
