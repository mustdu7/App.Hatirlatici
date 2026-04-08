// AppCalendarPicker.swift
// gerisayimpro
//
// Özel takvim bileşeni:
//   • Türkçe ay/gün isimleri
//   • Bugün otomatik halka ile işaretli
//   • Geçmiş günler soluk + çapraz çizgili
//   • Seçili gün dolu daire

import SwiftUI

// MARK: - AppCalendarPicker

struct AppCalendarPicker: View {

    @Binding var selection: Date

    @State private var displayMonth: Date

    private let cal    = Calendar(identifier: .gregorian)
    private let locale = Locale(identifier: "tr_TR")

    // Pazartesi başlangıçlı Türkçe kısa gün isimleri
    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    init(selection: Binding<Date>) {
        self._selection = selection
        self._displayMonth = State(
            initialValue: Self.startOfMonth(selection.wrappedValue)
        )
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 6) {
            monthHeader
            weekdayRow
            dayGrid
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Ay Başlığı

    private var monthHeader: some View {
        HStack {
            navButton(direction: -1, icon: "chevron.left")
            Spacer()
            Text(monthYearString)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Spacer()
            navButton(direction: +1, icon: "chevron.right")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func navButton(direction: Int, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                guard let m = cal.date(byAdding: .month, value: direction, to: displayMonth)
                else { return }
                displayMonth = m
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appPrimary.opacity(0.7))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gün Başlıkları

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { name in
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appPrimary.opacity(0.3))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Gün Izgarası

    private var dayGrid: some View {
        let days    = daysInMonth()
        let leading = leadingEmptyCells
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(0..<leading, id: \.self) { _ in Color.clear.frame(height: 32) }
            ForEach(days, id: \.self) { date in dayCell(for: date) }
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let today      = cal.startOfDay(for: Date())
        let cellDay    = cal.startOfDay(for: date)
        let isToday    = cellDay == today
        let isSelected = cal.isDate(cellDay, inSameDayAs: cal.startOfDay(for: selection))
        let isPast     = cellDay < today
        let number     = cal.component(.day, from: date)

        Button {
            withAnimation(.spring(response: 0.2)) {
                let selComps = cal.dateComponents([.hour, .minute, .second], from: selection)
                var newComps = cal.dateComponents([.year, .month, .day], from: date)
                newComps.hour   = selComps.hour
                newComps.minute = selComps.minute
                newComps.second = selComps.second
                selection = cal.date(from: newComps) ?? date
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 30, height: 30)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.appPrimary.opacity(0.55), lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                }

                Text("\(number)")
                    .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected ? Color.appBackground :
                        isPast     ? Color.appPrimary.opacity(0.18) :
                                     Color.appPrimary
                    )

                if isPast {
                    DiagonalLine()
                        .stroke(Color.appPrimary.opacity(0.14), lineWidth: 1)
                        .frame(width: 16, height: 16)
                }
            }
            .frame(height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Yardımcılar

    private var monthYearString: String {
        let fmt = DateFormatter()
        fmt.locale = locale
        fmt.dateFormat = "MMMM yyyy"
        let raw = fmt.string(from: displayMonth)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    private var leadingEmptyCells: Int {
        guard let first = cal.date(
            from: cal.dateComponents([.year, .month], from: displayMonth)
        ) else { return 0 }
        // weekday: Paz=1 … Cmt=7 → Pzt başlangıçlı index
        let wd = cal.component(.weekday, from: first)
        return (wd + 5) % 7
    }

    private func daysInMonth() -> [Date] {
        guard
            let range = cal.range(of: .day, in: .month, for: displayMonth),
            let first = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private static func startOfMonth(_ date: Date) -> Date {
        let cal  = Calendar(identifier: .gregorian)
        let comp = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comp) ?? date
    }
}

// MARK: - Çapraz Çizgi Şekli

private struct DiagonalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var date = Date()
    VStack {
        AppCalendarPicker(selection: $date)
            .padding()
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
            .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
