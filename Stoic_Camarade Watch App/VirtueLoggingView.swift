//
//  VirtueLoggingView.swift
//  StoicCamarade Watch App
//
//  Track the four cardinal Stoic virtues: Wisdom, Courage, Justice, Temperance
//

import SwiftUI
import Combine
import WatchKit

// MARK: - Virtue Model

enum StoicVirtue: String, Codable, CaseIterable {
    case wisdom = "Wisdom"
    case courage = "Courage"
    case justice = "Justice"
    case temperance = "Temperance"

    var icon: String {
        switch self {
        case .wisdom: return "brain.head.profile"
        case .courage: return "flame.fill"
        case .justice: return "scale.3d"
        case .temperance: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .wisdom: return .purple
        case .courage: return .orange
        case .justice: return .blue
        case .temperance: return .green
        }
    }

    var description: String {
        switch self {
        case .wisdom: return "Knowledge & good judgment"
        case .courage: return "Facing fears & adversity"
        case .justice: return "Fairness & doing right"
        case .temperance: return "Self-control & moderation"
        }
    }
}

struct VirtueLog: Codable, Identifiable {
    let id: UUID
    let virtue: StoicVirtue
    let date: Date
    var note: String?

    init(virtue: StoicVirtue, note: String? = nil) {
        self.id = UUID()
        self.virtue = virtue
        self.date = Date()
        self.note = note
    }
}

// MARK: - Virtue Manager

class VirtueManager: ObservableObject {
    static let shared = VirtueManager()

    @Published var logs: [VirtueLog] = []

    private let logsKey = "stoic_virtue_logs"

    init() {
        loadLogs()
    }

    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([VirtueLog].self, from: data) {
            // Keep last 100 logs
            logs = Array(decoded.suffix(100))
        }
    }

    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: logsKey)
        }
    }

    func logVirtue(_ virtue: StoicVirtue, note: String? = nil) {
        let log = VirtueLog(virtue: virtue, note: note)
        logs.append(log)
        saveLogs()
    }

    func getTodayCount(for virtue: StoicVirtue) -> Int {
        let calendar = Calendar.current
        return logs.filter {
            $0.virtue == virtue && calendar.isDateInToday($0.date)
        }.count
    }

    func getWeekCount(for virtue: StoicVirtue) -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return logs.filter {
            $0.virtue == virtue && $0.date >= weekAgo
        }.count
    }

    func getTotalCount(for virtue: StoicVirtue) -> Int {
        logs.filter { $0.virtue == virtue }.count
    }

    func getTodayTotal() -> Int {
        let calendar = Calendar.current
        return logs.filter { calendar.isDateInToday($0.date) }.count
    }

    func getWeeklyProgress() -> [StoicVirtue: Int] {
        var progress: [StoicVirtue: Int] = [:]
        for virtue in StoicVirtue.allCases {
            progress[virtue] = getWeekCount(for: virtue)
        }
        return progress
    }
}

// MARK: - Virtue Logging View

struct VirtueLoggingView: View {
    @ObservedObject private var manager = VirtueManager.shared
    @State private var showingLogConfirmation = false
    @State private var lastLoggedVirtue: StoicVirtue?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerSection

                // Virtue grid
                virtueGrid

                // Weekly progress bar
                weeklyProgressBar

                // Recent logs
                if !manager.logs.isEmpty {
                    recentLogs
                }
            }
            .padding()
        }
        .navigationTitle("Logging")
        .sheet(isPresented: $showingLogConfirmation) {
            logConfirmationSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Track Your Virtues")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            Text("Tap when you practice a virtue")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Virtue Grid

    private var virtueGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(StoicVirtue.allCases, id: \.self) { virtue in
                VirtueButton(virtue: virtue) {
                    manager.logVirtue(virtue)
                    lastLoggedVirtue = virtue
                    showingLogConfirmation = true
                }
            }
        }
    }

    // MARK: - Weekly Progress Bar

    private var weeklyProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("This Week")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(totalWeeklyCount) logged")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }

            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(StoicVirtue.allCases, id: \.self) { virtue in
                        let count = manager.getWeekCount(for: virtue)
                        let total = max(totalWeeklyCount, 1)
                        let width = (CGFloat(count) / CGFloat(total)) * geo.size.width

                        if count > 0 {
                            Rectangle()
                                .fill(virtue.color)
                                .frame(width: max(width, 4))
                        }
                    }
                }
            }
            .frame(height: 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
        }
    }

    private var totalWeeklyCount: Int {
        StoicVirtue.allCases.reduce(0) { $0 + manager.getWeekCount(for: $1) }
    }

    // MARK: - Recent Logs

    private var recentLogs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.system(size: 10))
                .foregroundColor(.gray)

            ForEach(manager.logs.suffix(3).reversed()) { log in
                HStack(spacing: 8) {
                    Image(systemName: log.virtue.icon)
                        .font(.system(size: 12))
                        .foregroundColor(log.virtue.color)

                    Text(log.virtue.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.white)

                    Spacer()

                    Text(formatTime(log.date))
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
        )
    }

    // MARK: - Log Confirmation Sheet

    private var logConfirmationSheet: some View {
        VStack(spacing: 16) {
            if let virtue = lastLoggedVirtue {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(virtue.color)

                Text("\(virtue.rawValue) Logged.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("Today: \(manager.getTodayCount(for: virtue))")
                    .font(.system(size: 12))
                    .foregroundColor(virtue.color)

                // Week tracker
                WeekTrackerView(virtue: virtue, manager: manager)
            }

            Button(action: { showingLogConfirmation = false }) {
                Text("Done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Virtue Button

import SwiftUI
import Combine
import WatchKit

// ...

struct VirtueButton: View {
    let virtue: StoicVirtue
    let action: () -> Void

    var body: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            action()
        }) {
            VStack(spacing: 8) {
                PremiumAssets.VirtueIcon(virtue: mapVirtue(virtue), size: 36)
                    .padding(.bottom, 4)

                Text(virtue.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(virtue.color.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func mapVirtue(_ virtue: StoicVirtue) -> PremiumAssets.VirtueIcon.Virtue {
        switch virtue {
        case .wisdom: return .wisdom
        case .courage: return .courage
        case .justice: return .justice
        case .temperance: return .temperance
        }
    }
}

// MARK: - Week Tracker View

struct WeekTrackerView: View {
    let virtue: StoicVirtue
    let manager: VirtueManager

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let hasLog = hasLogForDay(dayOffset)
                Rectangle()
                    .fill(hasLog ? virtue.color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .cornerRadius(2)
            }
        }
    }

    private func hasLogForDay(_ daysAgo: Int) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!

        return manager.logs.contains { log in
            log.virtue == virtue && calendar.isDate(log.date, inSameDayAs: targetDate)
        }
    }
}

#Preview {
    NavigationView {
        VirtueLoggingView()
    }
}
