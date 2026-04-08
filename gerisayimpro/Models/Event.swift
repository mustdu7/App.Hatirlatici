// Event.swift
// gerisayimpro

import Foundation
import SwiftData

// MARK: - RecurrenceRule

enum RecurrenceRule: String, Codable, CaseIterable {
    case daily, weekly, monthly, yearly

    var displayName: String {
        switch self {
        case .daily:   return "Her gün"
        case .weekly:  return "Her hafta"
        case .monthly: return "Her ay"
        case .yearly:  return "Her yıl"
        }
    }
}

// MARK: - Event

@Model
final class Event {

    var id:             UUID
    var title:          String
    var date:           Date
    var icon:           String
    var colorHex:       String
    var note:           String?
    var imageData:      Data?
    var isRecurring:    Bool
    var recurrenceRule: RecurrenceRule?
    var createdAt:      Date

    @Relationship(deleteRule: .cascade)
    var notifications: [EventNotification]

    init(
        id:             UUID                = UUID(),
        title:          String,
        date:           Date,
        icon:           String              = "calendar",
        note:           String?             = nil,
        imageData:      Data?              = nil,
        isRecurring:    Bool               = false,
        recurrenceRule: RecurrenceRule?    = nil,
        notifications:  [EventNotification] = [],
        createdAt:      Date               = Date()
    ) {
        self.id             = id
        self.title          = title
        self.date           = date
        self.icon           = icon
        self.colorHex       = "#007AFF"
        self.note           = note
        self.imageData      = imageData
        self.isRecurring    = isRecurring
        self.recurrenceRule = recurrenceRule
        self.notifications  = notifications
        self.createdAt      = createdAt
    }
}

// MARK: - Computed Properties

extension Event {

    var daysRemaining: Int {
        let target = isRecurring ? (nextOccurrence ?? date) : date
        return Calendar.current.daysUntil(target)
    }

    var hoursRemaining: Int {
        let target = isRecurring ? (nextOccurrence ?? date) : date
        return Int(target.timeIntervalSinceNow / 3_600)
    }

    var isPast: Bool {
        if isRecurring { return false }
        return date < Date()
    }

    var isToday: Bool {
        let target = isRecurring ? (nextOccurrence ?? date) : date
        return Calendar.current.isDateInToday(target)
    }

    var nextOccurrence: Date? {
        guard isRecurring, recurrenceRule != nil else { return nil }
        return RecurringEventService.shared.nextOccurrence(for: self, after: Date())
    }
}

