// EventViewModel.swift
// gerisayimpro

import Foundation
import SwiftData
import WidgetKit

enum EventError: LocalizedError {
    case invalidTitle
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidTitle:        return "Etkinlik adı boş olamaz."
        case .saveFailed(let e):   return "Kayıt hatası: \(e.localizedDescription)"
        case .deleteFailed(let e): return "Silme hatası: \(e.localizedDescription)"
        }
    }
}

@Observable
@MainActor
final class EventViewModel {

    var events:       [Event] = []
    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    var upcomingEvents: [Event] {
        events.filter { !$0.isPast }.sorted {
            let a = $0.isRecurring ? ($0.nextOccurrence ?? $0.date) : $0.date
            let b = $1.isRecurring ? ($1.nextOccurrence ?? $1.date) : $1.date
            return a < b
        }
    }

    var pastEvents:  [Event] { events.filter {  $0.isPast  }.sorted { $0.date > $1.date } }
    var todayEvents: [Event] { events.filter {  $0.isToday } }

    func addEvent(
        title:          String,
        date:           Date,
        icon:           String          = "calendar",
        note:           String?         = nil,
        imageData:      Data?           = nil,
        isRecurring:    Bool            = false,
        recurrenceRule: RecurrenceRule? = nil
    ) async throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EventError.invalidTitle }
        let event = Event(title: trimmed, date: date, icon: icon,
                          note: note, imageData: imageData,
                          isRecurring: isRecurring, recurrenceRule: recurrenceRule)
        modelContext.insert(event)
        do    { try modelContext.save() }
        catch { modelContext.delete(event); throw EventError.saveFailed(error) }
        events.append(event)
        await scheduleNotifications(for: event)
        WidgetCenter.shared.reloadAllTimelines()
        await NotificationService.shared.updateBadge(for: events)
    }

    func deleteEvent(_ event: Event) async throws {
        cancelNotifications(for: event)
        modelContext.delete(event)
        do    { try modelContext.save() }
        catch { throw EventError.deleteFailed(error) }
        events.removeAll { $0.id == event.id }
        WidgetCenter.shared.reloadAllTimelines()
        await NotificationService.shared.updateBadge(for: events)
    }

    func updateEvent(_ event: Event) async throws {
        guard !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw EventError.invalidTitle }
        do    { try modelContext.save() }
        catch { throw EventError.saveFailed(error) }
        cancelNotifications(for: event)
        await scheduleNotifications(for: event)
        WidgetCenter.shared.reloadAllTimelines()
        await NotificationService.shared.updateBadge(for: events)
    }

    func fetchEvents() async throws {
        isLoading = true
        defer { isLoading = false }
        let desc = FetchDescriptor<Event>(sortBy: [SortDescriptor(\.date)])
        do    { events = try modelContext.fetch(desc) }
        catch { throw EventError.saveFailed(error) }
        WidgetCenter.shared.reloadAllTimelines()
        await NotificationService.shared.updateBadge(for: events)
    }

    func scheduleNotifications(for event: Event) async {
        for n in event.notifications where n.isEnabled {
            try? await NotificationService.shared.scheduleNotification(for: event, offsetSeconds: n.offsetSeconds)
        }
    }

    func cancelNotifications(for event: Event) {
        NotificationService.shared.cancelNotifications(for: event.id)
    }

    func refreshAllNotifications() async {
        await NotificationService.shared.refreshAllNotifications(events: events)
    }
}
