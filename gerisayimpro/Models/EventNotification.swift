// EventNotification.swift
// gerisayimpro

import Foundation
import SwiftData

@Model
final class EventNotification {

    var id:            UUID
    var offsetSeconds: TimeInterval
    var isEnabled:     Bool

    init(id: UUID = UUID(), offsetSeconds: TimeInterval, isEnabled: Bool = true) {
        self.id            = id
        self.offsetSeconds = offsetSeconds
        self.isEnabled     = isEnabled
    }

    var humanReadableOffset: String { offsetSeconds.offsetLabel }
}
