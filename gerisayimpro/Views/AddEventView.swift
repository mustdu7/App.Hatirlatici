// AddEventView.swift
// gerisayimpro
//
// Yeni etkinlik ekleme ve mevcut etkinliği düzenleme sheet'i.
// editingEvent nil → ekleme modu | dolu → düzenleme modu

import SwiftUI
import SwiftData
import UIKit
import PhotosUI
import UserNotifications

// MARK: - AddEventView

@MainActor
struct AddEventView: View {

    // MARK: Environment

    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)     private var dismiss

    // MARK: Düzenleme Modu

    var editingEvent: Event? = nil

    // MARK: Form State

    @State private var title:           String          = ""
    @State private var date:            Date            = Self.defaultDate()
    @State private var selectedIcon:    String          = "calendar"
    @State private var isRecurring:     Bool            = false
    @State private var recurrenceRule:  RecurrenceRule  = .yearly
    @State private var selectedOffsets:  Set<TimeInterval>  = []
    @State private var note:             String             = ""
    @State private var selectedPhoto:    PhotosPickerItem?  = nil
    @State private var imageData:        Data?              = nil
    @State private var showIconPicker:   Bool               = false
    @State private var showNotifPicker:  Bool               = false
    @State private var titleIsInvalid:   Bool               = false
    @State private var isSaving:         Bool               = false
    @State private var errorMessage:     String?            = nil

    // MARK: Sabitler

    private let availableIcons: [String] = [
        "calendar",       "gift",           "airplane",       "heart.fill",    "star.fill",
        "trophy.fill",    "graduationcap.fill", "car.fill",   "house.fill",    "briefcase.fill",
        "music.note",     "camera.fill",
    ]

    private let notificationPresets: [(label: String, offset: TimeInterval)] = [
        ("Etkinlik anında",  0),
        ("15 dakika önce",   15 * 60),
        ("1 saat önce",      3_600),
        ("1 gün önce",       86_400),
        ("3 gün önce",       3 * 86_400),
        ("1 hafta önce",     604_800),
    ]

    // MARK: Computed

    private var isEditing: Bool { editingEvent != nil }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Arka plan
            Color.appBackground.ignoresSafeArea()

            // Kaydırılabilir form içeriği
            ScrollView {
                VStack(spacing: 0) {
                    pillIndicator
                    headerTitle
                    formContent
                    // Alt buton için boşluk
                    Spacer(minLength: 100)
                }
            }
            .scrollIndicators(.hidden)

            // Sabit alt "Kaydet" butonu
            saveButton
        }
        .onAppear(perform: populateIfEditing)
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Üst Bileşenler

    /// Sheet pill göstergesi
    private var pillIndicator: some View {
        Capsule()
            .fill(Color.appPrimary.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 20)
    }

    /// Başlık
    private var headerTitle: some View {
        Text(isEditing ? "Etkinliği Düzenle" : "Yeni Etkinlik")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
    }

    // MARK: - Form İçeriği

    private var formContent: some View {
        VStack(spacing: 12) {
            nameSection
            dateSection
            noteSection
            imageSection
            recurrenceSection
            notificationSection
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }

    // MARK: İsim Alanı (+ ikon butonu sağda)

    private var nameSection: some View {
        HStack(spacing: 0) {
            TextField("", text: $title)
                .onChange(of: title) { _, _ in
                    if titleIsInvalid { titleIsInvalid = false }
                }
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary)
                .placeholder(when: title.isEmpty) {
                    Text("Etkinlik adı")
                        .font(AppFont.body())
                        .foregroundStyle(Color.appPrimary.opacity(0.2))
                }
                .padding(AppSpacing.cardPadding)

            // Dikey ayırıcı
            Rectangle()
                .fill(Color.appBorder)
                .frame(width: 0.5)
                .padding(.vertical, 10)

            // İkon seçim butonu
            Button {
                showIconPicker = true
            } label: {
                Image(systemName: selectedIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.appPrimary.opacity(0.7))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.plain)
        }
        .appCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardRadius)
                .strokeBorder(
                    Color(red: 1.0, green: 0.27, blue: 0.23).opacity(titleIsInvalid ? 0.7 : 0),
                    lineWidth: 1.5
                )
                .animation(.easeInOut(duration: 0.2), value: titleIsInvalid)
        )
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
                .presentationDetents([.height(300)])
                .presentationBackground(Color.appSurface)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: İkon Seçici Sheet

    private var iconPickerSheet: some View {
        VStack(spacing: 20) {
            Text("İkon Seç")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appPrimary.opacity(0.5))
                .padding(.top, 20)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                spacing: 12
            ) {
                ForEach(availableIcons, id: \.self) { icon in
                    iconCell(icon)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2)) {
                                selectedIcon = icon
                            }
                            showIconPicker = false
                        }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: Tarih Seçici

    private var daysFromNowText: String {
        let days = Calendar.current.daysUntil(date)
        if days == 0  { return "Bugün" }
        if days > 0   { return "\(days) gün sonra" }
        return "\(abs(days)) gün önce"
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Bölüm etiketi
            Text("Tarih")
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .padding(.horizontal, AppSpacing.cardPadding)
                .padding(.top, AppSpacing.cardPadding)

            AppCalendarPicker(selection: $date)
                .padding(.horizontal, AppSpacing.cardPadding - 8)

            // "X gün sonra" önizleme etiketi
            Text(daysFromNowText)
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, AppSpacing.cardPadding)
                .animation(.spring(response: 0.3), value: daysFromNowText)
        }
        .appCard()
    }

    // MARK: Not Alanı

    private let noteLimit = 100

    private var noteSection: some View {
        HStack(alignment: .top, spacing: 0) {
            TextField("", text: $note, axis: .vertical)
                .onChange(of: note) { _, new in
                    if new.count > noteLimit { note = String(new.prefix(noteLimit)) }
                }
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1...3)
                .placeholder(when: note.isEmpty) {
                    Text("Not ekle...")
                        .font(AppFont.body())
                        .foregroundStyle(Color.appPrimary.opacity(0.2))
                }
                .padding(AppSpacing.cardPadding)

            Text("\(noteLimit - note.count)")
                .font(.system(size: 11, weight: .regular).monospacedDigit())
                .foregroundStyle(
                    note.count >= noteLimit
                        ? Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.7)
                        : Color.appPrimary.opacity(0.2)
                )
                .padding(.top, AppSpacing.cardPadding)
                .padding(.trailing, 12)
                .animation(.easeInOut(duration: 0.15), value: note.count)
        }
        .appCard()
    }

    // MARK: Görsel Alanı

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Görsel")
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .padding(.horizontal, AppSpacing.cardPadding)
                .padding(.top, AppSpacing.cardPadding)

            if let imageData, let uiImage = UIImage(data: imageData) {
                // Seçili görsel önizlemesi
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, AppSpacing.cardPadding)
                        .padding(.top, 8)
                        .padding(.bottom, AppSpacing.cardPadding)

                    // Kaldır butonu
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            self.imageData = nil
                            selectedPhoto  = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.appPrimary.opacity(0.8))
                            .background(Color.appBackground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.trailing, AppSpacing.cardPadding + 8)
                }
            } else {
                // Seçim butonu
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Galeriden Ekle")
                            .font(AppFont.body())
                    }
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.cardPadding)
                }
            }
        }
        .appCard()
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    withAnimation(.spring(response: 0.3)) {
                        imageData = img.jpegData(compressionQuality: 0.75)
                    }
                }
            }
        }
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        return Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(isSelected ? Color.appBackground : Color.appPrimary)
            .frame(width: 44, height: 44)
            .background(
                isSelected ? Color.appPrimary : Color.appSurface,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.appPrimary : Color.appBorder,
                        lineWidth: 0.5
                    )
            )
            .animation(.spring(response: 0.2), value: isSelected)
    }

    // MARK: Tekrar

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toggle satırı
            HStack {
                Text("Tekrarlayan")
                    .font(AppFont.body())
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Toggle("", isOn: $isRecurring.animation(.spring(response: 0.3, dampingFraction: 0.7)))
                    .tint(Color.appPrimary)
                    .labelsHidden()
            }
            .padding(AppSpacing.cardPadding)

            // Kural seçici — sadece tekrarlayan açıksa göster
            if isRecurring {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, AppSpacing.cardPadding)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tekrar Sıklığı")
                        .font(AppFont.secondary())
                        .foregroundStyle(Color.appPrimary.opacity(0.4))

                    HStack(spacing: 8) {
                        ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                            ruleChip(rule)
                        }
                        Spacer()
                    }
                }
                .padding(AppSpacing.cardPadding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .appCard()
    }

    private func ruleChip(_ rule: RecurrenceRule) -> some View {
        let isSelected = recurrenceRule == rule && isRecurring
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                recurrenceRule = rule
            }
        } label: {
            Text(rule.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.appBackground : Color.appPrimary.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.appPrimary : Color.appBackground,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.appPrimary : Color.appBorder,
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Bildirim

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ekleme butonu
            Button {
                showNotifPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Hatırlatıcı ekle")
                        .font(AppFont.body())
                }
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.cardPadding)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Hatırlatıcı Ekle", isPresented: $showNotifPicker, titleVisibility: .visible) {
                ForEach(
                    notificationPresets.filter { !selectedOffsets.contains($0.offset) },
                    id: \.offset
                ) { preset in
                    Button(preset.label) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            _ = selectedOffsets.insert(preset.offset)
                        }
                    }
                }
                Button("İptal", role: .cancel) {}
            }

            // Eklenen bildirimler chip olarak
            if !selectedOffsets.isEmpty {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, AppSpacing.cardPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedOffsets.sorted(), id: \.self) { offset in
                            notificationChip(offset: offset)
                        }
                    }
                    .padding(.horizontal, AppSpacing.cardPadding)
                    .padding(.vertical, 12)
                }
                .transition(.opacity)
            }
        }
        .appCard()
    }

    private func notificationChip(offset: TimeInterval) -> some View {
        HStack(spacing: 6) {
            Text(offset.offsetLabel)
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _ = selectedOffsets.remove(offset)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.appBackground, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.appBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Alt Kaydet Butonu

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            ZStack {
                if isSaving {
                    ProgressView().tint(Color.appBackground)
                } else {
                    Text("Kaydet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.appBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                isSaving ? Color.appPrimary.opacity(0.3) : Color.appPrimary,
                in: RoundedRectangle(cornerRadius: AppSpacing.cardRadius)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.bottom, 32)
        .background(Color.appBackground)
    }

    // MARK: - Yardımcı Fonksiyonlar

    /// Düzenleme modunda formu mevcut etkinlikle doldurur
    private func populateIfEditing() {
        guard let event = editingEvent else { return }
        title          = event.title
        date           = event.date
        selectedIcon   = event.icon
        isRecurring    = event.isRecurring
        recurrenceRule = event.recurrenceRule ?? .yearly
        selectedOffsets = Set(event.notifications.map(\.offsetSeconds))
        note           = event.note ?? ""
        imageData      = event.imageData
    }

    /// Kaydet: ekleme veya güncelleme
    private func save() async {
        // — Başlık validasyonu
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            withAnimation { titleIsInvalid = true }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // 2 saniye sonra kırmızı border kaldır
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { titleIsInvalid = false }
            }
            return
        }

        // — Hatırlatıcı seçildiyse bildirim izni kontrol et
        if !selectedOffsets.isEmpty {
            let status = await UNUserNotificationCenter.current().notificationSettings()
            switch status.authorizationStatus {
            case .denied:
                errorMessage = "Hatırlatıcıların çalışması için bildirim izni gerekli. Ayarlar → Geri Sayım Pro → Bildirimler'den etkinleştirin."
                return
            case .notDetermined:
                let granted = await NotificationService.shared.requestPermission()
                if !granted {
                    errorMessage = "Bildirim izni verilmedi. Hatırlatıcılar çalışmayacak."
                    return
                }
            default:
                break
            }
        }

        isSaving = true
        defer { isSaving = false }

        do {
            if let event = editingEvent {
                // Güncelleme modu
                event.title          = trimmedTitle
                event.date           = date
                event.icon           = selectedIcon
                event.isRecurring    = isRecurring
                event.recurrenceRule = isRecurring ? recurrenceRule : nil
                event.note           = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
                event.imageData      = imageData
                // Eski bildirimleri temizle, yenilerini ekle
                event.notifications  = buildNotifications()
                try await viewModel.updateEvent(event)
            } else {
                // Ekleme modu
                let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                try await viewModel.addEvent(
                    title:          trimmedTitle,
                    date:           date,
                    icon:           selectedIcon,
                    note:           trimmedNote.isEmpty ? nil : trimmedNote,
                    imageData:      imageData,
                    isRecurring:    isRecurring,
                    recurrenceRule: isRecurring ? recurrenceRule : nil
                )
                // Yeni eklenen etkinliğe bildirimleri ekle
                if !selectedOffsets.isEmpty,
                   let newEvent = viewModel.events.last(where: {
                       $0.title == trimmedTitle
                   }) {
                    newEvent.notifications = buildNotifications()
                    try? modelContext.save()
                    await viewModel.scheduleNotifications(for: newEvent)
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = error.localizedDescription
        }
    }

    /// Seçili offsetlerden EventNotification nesneleri oluşturur
    private func buildNotifications() -> [EventNotification] {
        selectedOffsets.map { offset in
            let n = EventNotification(offsetSeconds: offset)
            modelContext.insert(n)
            return n
        }
    }

    private static func defaultDate() -> Date { .now }
}

// MARK: - Placeholder Modifier Yardımcısı

extension View {
    /// TextField için özelleştirilmiş placeholder desteği
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

#Preview("Yeni Etkinlik") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Event.self, EventNotification.self, configurations: config)
    let vm = EventViewModel(modelContext: container.mainContext)

    AddEventView()
        .environment(vm)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
