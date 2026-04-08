// ContentView.swift
// gerisayimpro

import SwiftUI
import SwiftData

@MainActor
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: EventViewModel?
    @AppStorage("notifPermissionRequested") private var notifPermissionRequested = false
    @State private var showPermissionSheet = false

    var body: some View {
        Group {
            if let viewModel {
                EventListView()
                    .environment(viewModel)
            } else {
                loadingView
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            guard viewModel == nil else { return }
            let vm = EventViewModel(modelContext: modelContext)
            try? await vm.fetchEvents()
            viewModel = vm
            if !notifPermissionRequested {
                try? await Task.sleep(for: .milliseconds(600))
                showPermissionSheet = true
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            permissionSheet
                .presentationDetents([.height(300)])
                .presentationBackground(Color.appSurface)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - İzin Sheet

    private var permissionSheet: some View {
        VStack(spacing: 0) {
            Image(systemName: "bell.badge")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.appPrimary.opacity(0.7))
                .padding(.top, 32)
                .padding(.bottom, 20)

            Text("Hatırlatıcılar")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .padding(.bottom, 8)

            Text("Etkinliklerinizi zamanında hatırlatabilmemiz için bildirim iznine ihtiyacımız var.")
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

            Button {
                notifPermissionRequested = true
                showPermissionSheet = false
                Task { await NotificationService.shared.requestPermission() }
            } label: {
                Text("İzin Ver")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Button("Şimdi Değil") {
                notifPermissionRequested = true
                showPermissionSheet = false
            }
            .font(AppFont.secondary())
            .foregroundStyle(Color.appPrimary.opacity(0.3))
            .padding(.top, 14)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Yükleme Ekranı

    private var loadingView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.appPrimary.opacity(0.4))
                    .controlSize(.large)
                Text("Yükleniyor…")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.3))
            }
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: Event.self, EventNotification.self, configurations: config)
        c.mainContext.insert(Event(title: "Doğum Günü", date: Calendar.current.date(byAdding: .day, value: 7,  to: .now)!, icon: "birthday.cake"))
        c.mainContext.insert(Event(title: "Tatil",      date: Calendar.current.date(byAdding: .day, value: 42, to: .now)!, icon: "airplane"))
        return c
    }()
    ContentView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
