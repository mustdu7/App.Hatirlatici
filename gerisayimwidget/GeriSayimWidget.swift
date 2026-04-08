// GeriSayimWidget.swift
// gerisayimwidget

import WidgetKit
import SwiftUI

let wBg      = Color(red: 0.078, green: 0.078, blue: 0.078)
let wPrimary = Color(red: 0.941, green: 0.929, blue: 0.910)

// MARK: - Küçük Widget

struct CountdownSingleWidget: Widget {
    let kind = "CountdownSingleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            SmallWidgetView(event: entry.event)
                .containerBackground(wBg, for: .widget)
        }
        .configurationDisplayName("Geri Sayım")
        .description("En yakın etkinliğinizi gösterir.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Orta Widget

struct CountdownDoubleWidget: Widget {
    let kind = "CountdownDoubleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(wBg, for: .widget)
        }
        .configurationDisplayName("İkili Geri Sayım")
        .description("En yakın iki etkinliğinizi gösterir.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Bundle

@main
struct GeriSayimWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownSingleWidget()
        CountdownDoubleWidget()
    }
}
