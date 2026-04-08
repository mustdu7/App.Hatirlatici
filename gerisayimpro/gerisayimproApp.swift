// gerisayimproApp.swift
// gerisayimpro

import SwiftUI
import SwiftData

@Observable
final class AppRouter {
    var pendingEventId: UUID?
}

@main
struct gerisayimproApp: App {

    let container: ModelContainer
    @State private var router = AppRouter()

    init() { container = Self.makeModelContainer() }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .environment(router)
                .onOpenURL { url in
                    guard url.scheme == "gerisayimpro",
                          url.host   == "event",
                          let last   = url.pathComponents.last,
                          let uuid   = UUID(uuidString: last)
                    else { return }
                    router.pendingEventId = uuid
                }
        }
    }
}

private extension gerisayimproApp {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Event.self, EventNotification.self])
        let config = ModelConfiguration(
            "gerisayimpro.store",
            schema: schema,
            allowsSave: true,
            groupContainer: .identifier("group.com.must.gerisayimpro"),
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            #if DEBUG
            print("⚠️ App Group container oluşturulamadı: \(error)")
            #endif
            let fallback = ModelConfiguration("gerisayimpro.store", schema: schema, allowsSave: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}
