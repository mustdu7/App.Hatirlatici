// EventDetailView.swift
// gerisayimpro
//
// Etkinlik detay ekranı: arka planda büyük SF Symbol doku,
// hero geri sayım bölümü, bilgi kartı ve alt aksiyon satırı.
// TimelineView ile dakikada bir canlı güncelleme yapar.

import SwiftUI
import SwiftData

// MARK: - EventDetailView

@MainActor
struct EventDetailView: View {

    // MARK: Environment & Properties

    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let event: Event

    // MARK: State

    @State private var showingEdit:   Bool = false
    @State private var showingDelete: Bool = false

    // MARK: Hesaplanan

    private var targetDate: Date {
        event.isRecurring ? (event.nextOccurrence ?? event.date) : event.date
    }

    // MARK: Body

    var body: some View {
        // Dakikada bir güncelleme (saat/dakika bölümü için)
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            ZStack(alignment: .bottom) {
                // Arka plan
                Color.appBackground.ignoresSafeArea()

                // Kaydırılabilir içerik
                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader
                        VStack(spacing: 16) {
                            if let data = event.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadius))
                            }
                            infoCard
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, 24)
                        .padding(.bottom, 100) // alt butonlar için boşluk
                    }
                }
                .scrollIndicators(.hidden)

                // Sabit alt aksiyon çubuğu
                bottomActions
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(Color.appPrimary)
        .sheet(isPresented: $showingEdit) {
            AddEventView(editingEvent: event)
                .environment(viewModel)
        }
        .sheet(isPresented: $showingDelete) {
            deleteSheet
                .presentationDetents([.height(172)])
                .presentationBackground(Color.appSurface)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - Silme Onay Sheet'i

    private var deleteSheet: some View {
        VStack(spacing: 12) {
            Text("\"\(event.title)\" silinsin mi?")
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                Task {
                    showingDelete = false
                    try? await Task.sleep(for: .milliseconds(300))
                    try? await viewModel.deleteEvent(event)
                    dismiss()
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

    // MARK: - Hero Header

    /// Üst bölüm: başlık üstte, geri sayım sol altta, ikon sağ altta.
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Başlık — üstte, tam genişlik
            Text(event.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 28)

            // Alt satır: geri sayım (sol) + ikon (sağ)
            HStack(alignment: .bottom, spacing: 0) {
                heroCountdown
                Spacer(minLength: 16)
                Image(systemName: event.icon)
                    .font(.system(size: 80, weight: .regular))
                    .foregroundStyle(Color.appPrimary.opacity(0.15))
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(minHeight: 200)
    }

    // MARK: - Hero Geri Sayım

    @ViewBuilder
    private var heroCountdown: some View {
        if event.isToday {
            todayHero
        } else {
            standardHero
        }
    }

    /// Bugün için özel hero görünümü
    private var todayHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bugün!")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(targetDate, format: .dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide).year())
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary.opacity(0.4))
        }
    }

    /// Normal geri sayım hero bölümü
    private var standardHero: some View {
        let days:   Int  = abs(event.daysRemaining)
        let isPast: Bool = event.isPast

        return HStack(alignment: .bottom, spacing: 12) {
            // Sol: büyük rakam
            Text("\(days)")
                .font(.system(size: 96, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.appPrimary)
                .contentTransition(.numericText(countsDown: !isPast))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Sağ: "gün kaldı / geçti" + saat·dakika
            VStack(alignment: .leading, spacing: 6) {
                Text(isPast ? "gün geçti" : "gün kaldı")
                    .font(AppFont.body())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))

                subTimeRow
            }
            .padding(.bottom, 10) // rakamın taban çizgisiyle hizala
        }
    }

    /// "· X saat · X dakika ·" satırı
    @ViewBuilder
    private var subTimeRow: some View {
        let totalSeconds = abs(targetDate.timeIntervalSinceNow)
        let hours        = Int(totalSeconds) / 3_600 % 24
        let minutes      = Int(totalSeconds) / 60    % 60

        if event.isPast {
            // Geçmiş için gün sayısını göster (zaten herodan belli)
            EmptyView()
        } else {
            Text("· \(hours) saat · \(minutes) dakika ·")
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.25))
        }
    }

    // MARK: - Bilgi Kartı

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "calendar",
                label: "Tarih",
                value: event.date.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "tr_TR")))
            )

            if event.isRecurring, let rule = event.recurrenceRule {
                cardDivider
                infoRow(icon: "repeat", label: "Tekrar", value: rule.displayName)
            }

            if let note = event.note, !note.isEmpty {
                cardDivider
                noteRow(note: note)
            }

            if !event.notifications.isEmpty {
                cardDivider
                notificationsRows
            }
        }
        .appCard()
    }

    /// Not satırı
    private func noteRow(note: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Not")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
                Text(note)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppSpacing.cardPadding)
    }

    /// Tek bilgi satırı
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
                Text(value)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appPrimary)
            }

            Spacer()
        }
        .padding(AppSpacing.cardPadding)
    }

    /// Bildirim satırları
    private var notificationsRows: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "bell")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
                    .frame(width: 20)
                Text("Bildirimler")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.cardPadding)
            .padding(.top, AppSpacing.cardPadding)
            .padding(.bottom, 8)

            ForEach(event.notifications, id: \.id) { notif in
                HStack {
                    // İkon ve boşluk — diğer infoRow satırlarıyla hizalı (20pt + 14pt)
                    Color.clear.frame(width: 20)
                    Spacer().frame(width: 14)
                    Text(notif.humanReadableOffset)
                        .font(AppFont.body())
                        .foregroundStyle(
                            notif.isEnabled
                                ? Color.appPrimary
                                : Color.appPrimary.opacity(0.3)
                        )
                    Spacer()
                    if !notif.isEnabled {
                        Text("Kapalı")
                            .font(AppFont.secondary())
                            .foregroundStyle(Color.appPrimary.opacity(0.2))
                    }
                }
                .padding(.horizontal, AppSpacing.cardPadding)
                .padding(.vertical, 8)
            }
            .padding(.bottom, AppSpacing.cardPadding - 8)
        }
    }

    private var cardDivider: some View {
        Divider()
            .background(Color.appBorder)
            .padding(.horizontal, AppSpacing.cardPadding)
    }

    // MARK: - Alt Aksiyon Çubuğu

    private var bottomActions: some View {
        HStack(spacing: 0) {
            // Düzenle
            Button("Düzenle") {
                showingEdit = true
            }
            .font(AppFont.label(.regular))
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)

            // Dikey ayırıcı
            Rectangle()
                .fill(Color.appBorder)
                .frame(width: 0.5, height: 24)

            // Sil
            Button("Sil") {
                showingDelete = true
            }
            .font(AppFont.label(.regular))
            .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.23))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .background(Color.appSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 0.5)
        }
    }

}

// MARK: - Preview

#Preview {
    let event = Event(
        title: "Doğum Günü",
        date: Calendar.current.date(byAdding: .day, value: 7, to: .now)!,
        icon: "birthday.cake",
        isRecurring: true,
        recurrenceRule: .yearly
    )
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: Event.self, EventNotification.self, configurations: config)
        c.mainContext.insert(event)
        return c
    }()
    let vm = EventViewModel(modelContext: container.mainContext)
    NavigationStack {
        EventDetailView(event: event)
            .environment(vm)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
