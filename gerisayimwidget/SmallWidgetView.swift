// SmallWidgetView.swift
// gerisayimwidget

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {

    let event: WidgetEvent?

    var body: some View {
        if let event {
            eventView(event)
        } else {
            emptyView
        }
    }

    private func eventView(_ event: WidgetEvent) -> some View {
        ZStack(alignment: .bottomLeading) {
            wBg

            // Arka plan ikon
            Image(systemName: event.icon)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(wPrimary.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 2) {
                if event.isToday {
                    Text("Bugün!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(wPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(abs(event.daysRemaining))")
                            .font(.system(size: 48, weight: .bold).monospacedDigit())
                            .foregroundStyle(wPrimary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(event.isPast ? "gün\ngeçti" : "gün\nkaldı")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(wPrimary.opacity(0.4))
                            .lineLimit(2)
                    }
                }

                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(wPrimary.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
        }
    }

    private var emptyView: some View {
        ZStack {
            wBg
            VStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(wPrimary.opacity(0.3))
                Text("Etkinlik yok")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(wPrimary.opacity(0.3))
            }
        }
    }
}
