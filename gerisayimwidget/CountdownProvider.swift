// CountdownProvider.swift
// gerisayimwidget

import WidgetKit
import SwiftData
import Foundation

struct CountdownProvider: TimelineProvider {

    func placeholder(in context: Context) -> CountdownEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        if context.isPreview { completion(.placeholder); return }
        let top = fetchTopEvents(count: 2)
        completion(CountdownEntry(date: .now, event: top.first, secondEvent: top.count > 1 ? top[1] : nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let top         = fetchTopEvents(count: 2)
        let cal         = Calendar.current
        let now         = Date()
        let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)

        var entries: [CountdownEntry] = []
        var cursor = now
        while cursor < nextMidnight {
            entries.append(CountdownEntry(date: cursor, event: top.first, secondEvent: top.count > 1 ? top[1] : nil))
            cursor = cal.date(byAdding: .hour, value: 1, to: cursor) ?? nextMidnight
        }
        entries.append(CountdownEntry(date: nextMidnight, event: top.first, secondEvent: top.count > 1 ? top[1] : nil))
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func fetchTopEvents(count: Int) -> [WidgetEvent] {
        do {
            let config = ModelConfiguration(
                "gerisayimpro.store",
                groupContainer: .identifier("group.com.must.gerisayimpro")
            )
            let container = try ModelContainer(for: Event.self, EventNotification.self, configurations: config)
            let ctx       = ModelContext(container)
            var desc      = FetchDescriptor<Event>(sortBy: [SortDescriptor(\Event.date)])
            desc.fetchLimit = 100
            let now = Date()
            return try ctx.fetch(desc)
                .compactMap { raw -> (WidgetEvent, Date)? in
                    guard let target = effectiveDate(for: raw, after: now) else { return nil }
                    return (WidgetEvent(id: raw.id, title: raw.title, targetDate: target, icon: raw.icon), target)
                }
                .sorted { $0.1 < $1.1 }
                .prefix(count)
                .map(\.0)
        } catch { return [] }
    }

    private func effectiveDate(for event: Event, after now: Date) -> Date? {
        guard event.isRecurring, let _ = event.recurrenceRule else {
            return event.date >= Calendar.current.startOfDay(for: now) ? event.date : nil
        }
        return RecurringEventService.shared.nextOccurrence(for: event, after: now)
    }
}
