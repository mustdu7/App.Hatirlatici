// EventCard.swift
// gerisayimpro
//
// Etkinlik listesindeki her satır için yeniden kullanılabilir kart bileşeni.
// Tek renk kuralına uyar; hiyerarşi yalnızca opaklıkla kurulur.

import SwiftUI

// MARK: - EventCard

struct EventCard: View {

    let event: Event

    // MARK: Yardımcılar

    private var targetDate: Date {
        event.isRecurring ? (event.nextOccurrence ?? event.date) : event.date
    }

    // MARK: Body

    var body: some View {
        HStack(spacing: 12) {
            iconView
            infoView
            Spacer(minLength: 8)
            countdownView
        }
        .padding(.horizontal, AppSpacing.cardPadding)
        .padding(.vertical, 12)
        .appCard()
        // Geçmiş etkinlikler: tüm kart %30 opaklık
        .opacity(event.isPast ? 0.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: event.isPast)
    }

    // MARK: - Ikon

    /// Arka plansız sade SF Symbol
    private var iconView: some View {
        Image(systemName: event.icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.appPrimary.opacity(0.7))
            .frame(width: 28, height: 28)
    }

    // MARK: - Bilgi

    /// Sol orta: başlık + tarih
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(AppFont.label())
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)

            Text(targetDate, format: .dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide).year())
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.35))
        }
    }

    // MARK: - Geri Sayım

    /// Sağ taraf: büyük rakam + birim veya "Bugün"
    @ViewBuilder
    private var countdownView: some View {
        if event.isToday {
            // Bugün: sadece metin
            Text("Bugün")
                .font(AppFont.label(.bold))
                .foregroundStyle(Color.appPrimary)

        } else {
            // Standart: rakam üstte, birim altta
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(abs(countdownValue))")
                    .font(AppFont.cardNumber())
                    .foregroundStyle(Color.appPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: !event.isPast))

                Text(countdownUnit)
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
        }
    }

    // MARK: Hesaplanan Değerler

    private var countdownValue: Int {
        // Geçmiş → mutlak gün sayısı
        if event.isPast { return event.daysRemaining }
        // Aynı gün ama saat farkı var → saati göster
        if event.daysRemaining == 0 { return event.hoursRemaining }
        return event.daysRemaining
    }

    private var countdownUnit: String {
        if event.isPast     { return "gün önce" }
        if event.daysRemaining == 0 { return "saat"    }
        return "gün"
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVStack(spacing: AppSpacing.cardGap) {
            ForEach(0..<3) { i in
                let days = [7, 1, -3][i]
                let title = ["Doğum Günü", "Yarın!", "Geçmiş Etkinlik"][i]
                let icon  = ["birthday.cake", "star.fill", "flag.fill"][i]
                let event = Event(
                    title: title,
                    date: Calendar.current.date(byAdding: .day, value: days, to: .now)!,
                    icon: icon
                )
                EventCard(event: event)
                    .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
        .padding(.vertical, 16)
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
