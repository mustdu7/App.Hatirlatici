// NotificationService.swift
// gerisayimpro

import Foundation
import UserNotifications

enum NotificationError: LocalizedError {
    case permissionDenied
    case invalidDate(Date)
    case systemError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:    return "Bildirim izni reddedildi."
        case .invalidDate(let d):  return "Geçersiz tarih: \(d.formatted())"
        case .systemError(let e):  return e.localizedDescription
        }
    }
}

final class NotificationService {

    static let shared = NotificationService()
    private init() {}
    private let maxPending = 64

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleNotification(for event: Event, offsetSeconds: TimeInterval) async throws {
        let target  = event.isRecurring ? (event.nextOccurrence ?? event.date) : event.date
        let fireDate = target.addingTimeInterval(-offsetSeconds)
        guard fireDate > Date() else { throw NotificationError.invalidDate(fireDate) }

        let content      = UNMutableNotificationContent()
        content.title    = event.title
        content.body     = buildBody(event: event, offset: offsetSeconds)
        content.sound    = .default
        content.userInfo = ["eventId": event.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: fireDate),
            repeats: false
        )
        let id = "event_\(event.id.uuidString)_\(Int(offsetSeconds))"
        do {
            try await UNUserNotificationCenter.current()
                .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            throw NotificationError.systemError(error)
        }
    }

    func cancelNotifications(for eventId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier)
                .filter { $0.hasPrefix("event_\(eventId.uuidString)_") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func refreshAllNotifications(events: [Event]) async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        var entries: [(fireDate: Date, event: Event, offset: TimeInterval)] = []
        for event in events.filter({ !$0.isPast }) {
            let target = event.isRecurring ? (event.nextOccurrence ?? event.date) : event.date
            for notif in event.notifications where notif.isEnabled {
                let fire = target.addingTimeInterval(-notif.offsetSeconds)
                if fire > Date() { entries.append((fire, event, notif.offsetSeconds)) }
            }
        }
        entries.sort { $0.fireDate < $1.fireDate }
        for e in entries.prefix(maxPending) {
            try? await scheduleNotification(for: e.event, offsetSeconds: e.offset)
        }
    }

    func updateBadge(for events: [Event]) async {
        let count = events.filter { $0.isToday }.count
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }

    private func buildBody(event: Event, offset: TimeInterval) -> String {
        if offset == 0 { return "\(event.title) bugün!" }
        let days = Int(offset / 86_400)
        let hrs  = Int((offset.truncatingRemainder(dividingBy: 86_400)) / 3_600)
        if days > 0 { return "\(event.title) etkinliğine \(days) gün kaldı." }
        if hrs  > 0 { return "\(event.title) etkinliğine \(hrs) saat kaldı." }
        return "\(event.title) etkinliğine \(Int(offset/60)) dakika kaldı."
    }
}
