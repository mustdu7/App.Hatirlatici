// RecurringEventService.swift
// gerisayimpro

import Foundation

final class RecurringEventService {

    static let shared = RecurringEventService()
    private init() {}

    func nextOccurrence(for event: Event, after date: Date) -> Date? {
        guard event.isRecurring, let rule = event.recurrenceRule else { return nil }
        let cal = Calendar.current
        var candidate = event.date
        if candidate > date { return candidate }

        let component: Calendar.Component
        switch rule {
        case .daily:   component = .day
        case .weekly:  component = .weekOfYear
        case .monthly: component = .month
        case .yearly:  component = .year
        }

        var i = 0
        while candidate <= date, i < 1_000 {
            guard let next = cal.date(byAdding: component, value: 1, to: candidate) else { return nil }
            candidate = next; i += 1
        }

        if rule == .yearly {
            let orig = cal.dateComponents([.month, .day], from: event.date)
            if orig.month == 2, orig.day == 29 {
                let year   = cal.component(.year, from: candidate)
                let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
                if !isLeap {
                    var march = DateComponents()
                    march.year = year; march.month = 3; march.day = 1
                    candidate = cal.date(from: march) ?? candidate
                }
            }
        }
        return candidate > date ? candidate : nil
    }

    func allOccurrences(for event: Event, in range: DateInterval) -> [Date] {
        guard event.isRecurring, let rule = event.recurrenceRule else {
            return range.contains(event.date) ? [event.date] : []
        }
        let cal = Calendar.current
        var results: [Date] = []
        var current = event.date

        let component: Calendar.Component
        switch rule {
        case .daily:   component = .day
        case .weekly:  component = .weekOfYear
        case .monthly: component = .month
        case .yearly:  component = .year
        }

        while current < range.start {
            guard let next = cal.date(byAdding: component, value: 1, to: current) else { break }
            current = next
        }
        var count = 0
        while current <= range.end, count < 500 {
            if range.contains(current) { results.append(current) }
            guard let next = cal.date(byAdding: component, value: 1, to: current) else { break }
            current = next; count += 1
        }
        return results
    }
}
