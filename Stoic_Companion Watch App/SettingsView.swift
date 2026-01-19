//
//  SettingsView.swift
//  StoicCompanion Watch App
//
//  Settings for notifications and app preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var persistence = PersistenceManager.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @State private var showingResetConfirmation = false

    var body: some View {
        ZStack {
            // Nano Banana Pro: Animated Deep Background
            PremiumBackgroundView()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Notifications Section
                    notificationsSection
                        .padding(.top, 10)

                    // Statistics Section
                    statisticsSection

                    // Data Section
                    dataSection
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            notifications.checkAuthorizationStatus()
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("NOTIFICATIONS", icon: "bell.fill")

            // Authorization status
            if !notifications.isAuthorized {
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    Task { await notifications.requestAuthorization() }
                }) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("Enable Notifications")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(PremiumAssets.Colors.vibrantOrange)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 10) {
                    NotificationToggle(
                        title: "Morning Wisdom",
                        subtitle: formatTime(persistence.notificationSettings.morningTime),
                        icon: "sunrise.fill",
                        iconColor: .yellow,
                        isEnabled: $persistence.notificationSettings.morningEnabled,
                        time: $persistence.notificationSettings.morningTime,
                        onChanged: scheduleNotifications
                    )

                    NotificationToggle(
                        title: "Evening Reflection",
                        subtitle: formatTime(persistence.notificationSettings.eveningTime),
                        icon: "moon.fill",
                        iconColor: PremiumAssets.Colors.moonPurple,
                        isEnabled: $persistence.notificationSettings.eveningEnabled,
                        time: $persistence.notificationSettings.eveningTime,
                        onChanged: scheduleNotifications
                    )
                }
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("YOUR JOURNEY", icon: "chart.bar.fill")

            VStack(spacing: 12) {
                StatRow(label: "Total Quotes", value: "\(persistence.statistics.totalQuotesViewed)")
                StatRow(label: "Current Streak", value: "\(persistence.statistics.currentStreak) days")
                StatRow(label: "Longest Streak", value: "\(persistence.statistics.longestStreak) days")
                StatRow(label: "Favorites", value: "\(persistence.statistics.favoritesCount)")
                StatRow(label: "Marked Helpful", value: "\(persistence.statistics.helpfulCount)")
            }
            .padding(14)
            .background(
                PremiumAssets.GlassBackdrop(cornerRadius: 16)
            )
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Data", icon: "externaldrive.fill")

            Button(action: { showingResetConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
                .font(.system(size: 12))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    persistence.resetAllData()
                    Task {
                        await notifications.removeAllScheduledNotifications()
                    }
                }
            } message: {
                Text("This will delete all favorites, history, and statistics. This cannot be undone.")
            }

            // App version
            Text("StoicCompanion v1.1.0")
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(PremiumAssets.Colors.vibrantOrange)
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white.opacity(0.9))
                .tracking(1.5)
            Spacer()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func scheduleNotifications() {
        persistence.saveNotificationSettings()
        Task {
            await notifications.scheduleAllNotifications()
        }
    }
}

// MARK: - Notification Toggle

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isEnabled: Bool
    @Binding var time: Date
    let onChanged: () -> Void

    @State private var showingTimePicker = false

    var body: some View {
        Button(action: { 
            if isEnabled {
                WKInterfaceDevice.current().play(.click)
                showingTimePicker = true 
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)

                    if isEnabled {
                        Text(subtitle)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                            .tracking(0.5)
                    }
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(PremiumAssets.Colors.vibrantOrange)
                    .scaleEffect(0.8)
                    .onChange(of: isEnabled) { _, _ in
                        WKInterfaceDevice.current().play(.click)
                        onChanged()
                    }
            }
            .padding(10)
            .background(
                PremiumAssets.GlassBackdrop(cornerRadius: 12)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(time: $time, color: iconColor, onSave: {
                showingTimePicker = false
                onChanged()
            })
        }
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var time: Date
    let color: Color
    let onSave: () -> Void

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            
            VStack(spacing: 16) {
                Text("SET TIME")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(color)
                    .tracking(2)

                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    onSave()
                }) {
                    Text("SAVE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(color)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SettingsView()
    }
}
