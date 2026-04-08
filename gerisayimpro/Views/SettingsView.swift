// SettingsView.swift
// gerisayimpro
//
// Uygulama ayarları: bildirim izin durumu, sürüm bilgisi ve geliştirici.
// List .insetGrouped stil, appBackground üzerinde appSurface satırlar.

import SwiftUI
import UserNotifications
import WidgetKit

// MARK: - SettingsView

@MainActor
struct SettingsView: View {

    // MARK: Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission: Bool = false
    @State private var widgetReloaded: Bool = false

    // MARK: Uygulama Bilgileri

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                widgetSection
                appearanceSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(Color.appPrimary.opacity(0.4))
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(Color.appPrimary)
        .background(Color.appBackground.ignoresSafeArea())
        .task { await refreshNotificationStatus() }
    }

    // MARK: - Bildirimler Bölümü

    private var notificationsSection: some View {
        Section {
            // İzin durumu satırı
            HStack {
                settingsLabel(icon: "bell", text: "İzin Durumu")
                Spacer()
                Text(notificationStatusLabel)
                    .font(AppFont.secondary())
                    .foregroundStyle(notificationStatusColor)
            }
            .listRowBackground(Color.appSurface)

            // Durum göre aksiyon satırı
            if notificationStatus == .denied {
                Button {
                    openSettings()
                } label: {
                    Text("Ayarlar'da Etkinleştir")
                        .font(AppFont.body())
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowBackground(Color.appSurface)
            } else if notificationStatus == .notDetermined {
                Button {
                    Task { await requestPermission() }
                } label: {
                    HStack {
                        Text("İzin Ver")
                            .font(AppFont.body())
                            .foregroundStyle(Color.appPrimary)
                        Spacer()
                        if isRequestingPermission {
                            ProgressView().controlSize(.small).tint(Color.appPrimary)
                        }
                    }
                }
                .listRowBackground(Color.appSurface)
            } else if notificationStatus == .authorized || notificationStatus == .provisional {
                Button {
                    openSettings()
                } label: {
                    HStack {
                        Text("Bildirimleri Yönet")
                            .font(AppFont.body())
                            .foregroundStyle(Color.appPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appPrimary.opacity(0.4))
                    }
                }
                .listRowBackground(Color.appSurface)
            }
        } header: {
            sectionHeader("Bildirimler")
        }
    }

    // MARK: - Widget Bölümü

    private var widgetSection: some View {
        Section {
            Button {
                WidgetCenter.shared.reloadAllTimelines()
                widgetReloaded = true
                // 2 saniye sonra feedback'i sıfırla
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    widgetReloaded = false
                }
            } label: {
                HStack {
                    settingsLabel(icon: "rectangle.stack", text: "Widget'ı Yenile")
                    Spacer()
                    if widgetReloaded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.appPrimary.opacity(0.6))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: widgetReloaded)
            }
            .listRowBackground(Color.appSurface)
        } header: {
            sectionHeader("Widget")
        } footer: {
            Text("Ana ekran widget'ını hemen güncellemek için kullanın.")
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.2))
        }
    }

    // MARK: - Görünüm Bölümü

    private var appearanceSection: some View {
        Section {
            HStack {
                settingsLabel(icon: "moon.fill", text: "Tema")
                Spacer()
                Text("Koyu (Sabit)")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
            .listRowBackground(Color.appSurface)
        } header: {
            sectionHeader("Görünüm")
        } footer: {
            Text("Geri Sayım Pro her zaman koyu temada çalışır.")
                .font(AppFont.secondary())
                .foregroundStyle(Color.appPrimary.opacity(0.2))
        }
    }

    // MARK: - Hakkında Bölümü

    private var aboutSection: some View {
        Section {
            HStack {
                settingsLabel(icon: "info.circle", text: "Sürüm")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
            .listRowBackground(Color.appSurface)

            HStack {
                settingsLabel(icon: "person.fill", text: "Geliştirici")
                Spacer()
                Text("Mustafa Durna")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
            .listRowBackground(Color.appSurface)

            HStack {
                settingsLabel(icon: "envelope", text: "E-Posta")
                Spacer()
                Text("mustdu7@gmail.com")
                    .font(AppFont.secondary())
                    .foregroundStyle(Color.appPrimary.opacity(0.4))
            }
            .listRowBackground(Color.appSurface)
        } header: {
            sectionHeader("Hakkında")
        }
    }

    // MARK: - Yeniden Kullanılabilir Satır Bileşenleri

    private func settingsLabel(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appPrimary.opacity(0.4))
                .frame(width: 20)
            Text(text)
                .font(AppFont.body())
                .foregroundStyle(Color.appPrimary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFont.secondary())
            .foregroundStyle(Color.appPrimary.opacity(0.3))
            .textCase(nil)
    }

    // MARK: - Bildirim Yönetimi

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized:            return "Aktif ✓"
        case .denied:                return "Reddedildi"
        case .provisional:           return "Geçici"
        case .ephemeral:             return "Geçici"
        case .notDetermined:         return "Belirlenmedi"
        @unknown default:            return "Bilinmiyor"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return Color.appPrimary.opacity(0.6)
        case .denied:
            return Color.appPrimary.opacity(0.3)
        default:
            return Color.appPrimary.opacity(0.4)
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    private func requestPermission() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        _ = await NotificationService.shared.requestPermission()
        await refreshNotificationStatus()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
