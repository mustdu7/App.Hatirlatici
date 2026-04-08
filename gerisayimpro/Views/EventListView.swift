// EventListView.swift
// gerisayimpro
//
// Ana ekran: özelleştirilmiş başlık, segment seçici, etkinlik listesi,
// boş durum görünümü ve sağ alt FAB butonu.

import SwiftUI
import SwiftData
import UIKit

// MARK: - Sekme

private enum EventTab: String, CaseIterable {
    case upcoming = "Yaklaşan"
    case past     = "Geçmiş"
}

// MARK: - EventListView

@MainActor
struct EventListView: View {

    // MARK: Environment

    @Environment(EventViewModel.self) private var viewModel
    @Environment(AppRouter.self)      private var router

    // MARK: State

    @State private var selectedTab:      EventTab = .upcoming
    @State private var showingAdd:       Bool     = false
    @State private var showingSettings:  Bool     = false
    @State private var selectedEvent:    Event?   = nil
    @State private var editingEvent:     Event?   = nil
    @State private var searchText:       String   = ""
    @State private var showSearch:       Bool     = false
    @State private var showConfetti:     Bool     = false
    @State private var deletingEvent:    Event?   = nil

    // MARK: Computed

    private var displayedEvents: [Event] {
        let base: [Event]
        switch selectedTab {
        case .upcoming: base = viewModel.upcomingEvents
        case .past:     base = viewModel.pastEvents
        }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var shouldShowConfetti: Bool {
        selectedTab == .upcoming &&
        viewModel.upcomingEvents.isEmpty &&
        !viewModel.pastEvents.isEmpty
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Tam ekran arka plan (iOS 26 Liquid Glass için gerekli)
                Color.appBackground.ignoresSafeArea()

                // Ana içerik
                VStack(spacing: 0) {
                    headerView
                    if showSearch { searchBar }
                    controlRow
                    eventList
                }

                // Konfeti — tüm yaklaşan etkinlikler bitti
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }

                // Sağ alt FAB
                fabButton
            }
            .toolbar(.hidden, for: .navigationBar)
            // Navigasyon hedefi: etkinlik detay
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            // Yeni etkinlik sheet'i
            .sheet(isPresented: $showingAdd) {
                AddEventView()
                    .environment(viewModel)
            }
            // Düzenleme sheet'i (contextMenu'dan)
            .sheet(item: $editingEvent) { event in
                AddEventView(editingEvent: event)
                    .environment(viewModel)
            }
            // Ayarlar sheet'i
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            // Silme onayı
            .sheet(item: $deletingEvent) { event in
                deleteConfirmSheet(event: event)
                    .presentationDetents([.height(172)])
                    .presentationBackground(Color.appSurface)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            // Deep link: widget'tan gelen etkinlik ID'si ile navigate et
            .onChange(of: router.pendingEventId) { _, newId in
                guard let id = newId else { return }
                selectedEvent = viewModel.events.first { $0.id == id }
                router.pendingEventId = nil
            }
            // Konfeti: yaklaşan etkinlikler listesi boşaldığında tetikle
            .onChange(of: shouldShowConfetti) { _, show in
                if show {
                    showConfetti = true
                    Task {
                        try? await Task.sleep(for: .seconds(3.5))
                        showConfetti = false
                    }
                }
            }
        }
        .tint(Color.appPrimary)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Başlık

    private var headerView: some View {
        HStack(alignment: .center) {
            // Uygulama ikonu — kompakt
            AppIcon_Arc()
                .frame(width: 1024, height: 1024)
                .scaleEffect(34.0 / 1024.0)
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSearch.toggle()
                    if !showSearch { searchText = "" }
                }
            } label: {
                Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.appPrimary.opacity(showSearch ? 0.6 : 0.5))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Arama Çubuğu

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary.opacity(0.4))
            TextField("", text: $searchText)
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary)
                .placeholder(when: searchText.isEmpty) {
                    Text("Etkinlik ara...")
                        .font(AppFont.body())
                        .foregroundStyle(Color.appPrimary.opacity(0.25))
                }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appPrimary.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Kontrol Satırı (segment sağa yaslanmış)

    private var controlRow: some View {
        HStack {
            Spacer()
            AppSegmentedPicker(
                selection: $selectedTab,
                options: EventTab.allCases.map { (label: $0.rawValue, value: $0) }
            )
            .frame(width: 190)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Etkinlik Listesi

    private var eventList: some View {
        List {
            ForEach(displayedEvents, id: \.persistentModelID) { event in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedEvent = event
                } label: {
                    EventCard(event: event)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(
                        top: AppSpacing.cardGap / 2,
                        leading: AppSpacing.screenPadding,
                        bottom: AppSpacing.cardGap / 2,
                        trailing: AppSpacing.screenPadding
                    )
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        deletingEvent = event
                    } label: {
                        Label("Sil", systemImage: "trash.fill")
                    }
                    .tint(Color(red: 1.0, green: 0.23, blue: 0.19))
                }
                .contextMenu {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        editingEvent = event
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        Task { try? await viewModel.deleteEvent(event) }
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayedEvents.map(\.id))
        .overlay {
            if displayedEvents.isEmpty && !viewModel.isLoading {
                emptyStateView
            }
        }
    }

    // MARK: - Silme Onay Sheet

    private func deleteConfirmSheet(event: Event) -> some View {
        VStack(spacing: 12) {
            Text("\"\(event.title)\" silinsin mi?")
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                Task {
                    deletingEvent = nil
                    try? await Task.sleep(for: .milliseconds(300))
                    try? await viewModel.deleteEvent(event)
                }
            } label: {
                Text("Sil")
                    .font(AppFont.label())
                    .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.23))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Boş Durum

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary.opacity(0.25))

            Text("Henüz etkinlik yok")
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        // Segment seçici alanını kapsamasın
        .ignoresSafeArea(edges: [])
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            showingAdd = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: AppSpacing.fabSize, height: AppSpacing.fabSize)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.appBackground)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, AppSpacing.fabMargin)
        .padding(.bottom, AppSpacing.fabMargin)
        .shadow(color: Color.appPrimary.opacity(0.15), radius: 12, y: 4)
        .accessibilityLabel("Yeni etkinlik ekle")
    }
}

// MARK: - Preview

#Preview {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: Event.self, EventNotification.self, configurations: config)
        c.mainContext.insert(Event(title: "Doğum Günü", date: Calendar.current.date(byAdding: .day, value: 7,  to: .now)!, icon: "birthday.cake"))
        c.mainContext.insert(Event(title: "Tatil",      date: Calendar.current.date(byAdding: .day, value: 42, to: .now)!, icon: "airplane"))
        c.mainContext.insert(Event(title: "Sınav",      date: Calendar.current.date(byAdding: .day, value: 1,  to: .now)!, icon: "graduationcap.fill"))
        return c
    }()
    let vm = EventViewModel(modelContext: container.mainContext)
    EventListView()
        .environment(vm)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
