// MediumWidgetView.swift
// gerisayimwidget

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {

    let entry: CountdownEntry

    var body: some View {
        HStack(spacing: 0) {
            eventCell(entry.event, isLeft: true)
            Rectangle()
                .fill(wPrimary.opacity(0.08))
                .frame(width: 0.5)
                .padding(.vertical, 16)
            eventCell(entry.secondEvent, isLeft: false)
        }
        .background(wBg)
    }

    @ViewBuilder
    private func eventCell(_ event: WidgetEvent?, isLeft: Bool) -> some View {
        if let event {
            Link(destination: URL(string: "gerisayimpro://event/\(event.id.uuidString)")!) {
                ZStack(alignment: .bottomLeading) {
                    Image(systemName: event.icon)
                        .font(.system(size: 60, weight: .thin))
                        .foregroundStyle(wPrimary.opacity(0.05))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 10)
                        .padding(.trailing, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        if event.isToday {
                            Text("Bugün!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(wPrimary)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text("\(abs(event.daysRemaining))")
                                    .font(.system(size: 34, weight: .bold).monospacedDigit())
                                    .foregroundStyle(wPrimary)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                Text(event.isPast ? "gün\ngeçti" : "gün\nkaldı")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(wPrimary.opacity(0.4))
                                    .lineLimit(2)
                            }
                        }
                        Text(event.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(wPrimary.opacity(0.7))
                            .lineLimit(2)
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(wBg)
            }
        } else {
            ZStack {
                wBg
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .thin))
                    .foregroundStyle(wPrimary.opacity(0.2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
