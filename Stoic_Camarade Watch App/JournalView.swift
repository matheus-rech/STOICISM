//
//  JournalView.swift
//  StoicCamarade Watch App
//
//  Quick journaling for stoic reflection on the watch
//

import SwiftUI
import Combine

// MARK: - Journal Entry Model

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var content: String
    var mood: JournalMood?
    var tags: [String]

    init(content: String = "", mood: JournalMood? = nil, tags: [String] = []) {
        self.id = UUID()
        self.date = Date()
        self.content = content
        self.mood = mood
        self.tags = tags
    }

    enum JournalMood: String, Codable, CaseIterable {
        case stoic = "Stoic"
        case grateful = "Grateful"
        case challenged = "Challenged"
        case peaceful = "Peaceful"
        case anxious = "Anxious"

        var icon: String {
            switch self {
            case .stoic: return "face.smiling"
            case .grateful: return "heart.fill"
            case .challenged: return "figure.climbing"
            case .peaceful: return "leaf.fill"
            case .anxious: return "wind"
            }
        }

        var color: Color {
            switch self {
            case .stoic: return .orange
            case .grateful: return .red
            case .challenged: return .yellow
            case .peaceful: return .green
            case .anxious: return .blue
            }
        }
    }
}

// MARK: - Journal Manager

class JournalManager: ObservableObject {
    static let shared = JournalManager()

    @Published var entries: [JournalEntry] = []

    private let entriesKey = "stoic_journal_entries"

    init() {
        loadEntries()
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = Array(decoded.suffix(50)) // Keep last 50 entries
        }
    }

    func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }

    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        saveEntries()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        saveEntries()
    }

    func getTodayEntries() -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }

    func getEntriesForWeek() -> [JournalEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.date >= weekAgo }
    }

    var totalEntries: Int { entries.count }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Journal View

struct JournalView: View {
    @ObservedObject private var manager = JournalManager.shared
    @State private var showingNewEntry = false
    @State private var newEntryText = ""
    @State private var selectedMood: JournalEntry.JournalMood?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Quick add button
                quickAddButton

                // Stats
                statsRow

                // Recent entries
                if !manager.entries.isEmpty {
                    recentEntriesSection
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .navigationTitle("Journal")
        .sheet(isPresented: $showingNewEntry) {
            newEntrySheet
        }
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button(action: { showingNewEntry = true }) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("New Entry")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(manager.totalEntries)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(manager.currentStreak)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Streak")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(manager.getTodayEntries().count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    Text("Today")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }

            // AI Insights Button
            if manager.entries.count >= 3 {
                Button(action: {
                    Task { await generateAIInsights() }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(isLoadingInsights ? "Analyzing..." : "AI Insights")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.purple)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
        )
        .sheet(isPresented: $showingInsights) {
            insightsSheet
        }
    }

    @State private var showingInsights = false
    @State private var isLoadingInsights = false
    @State private var aiInsights = ""

    private var insightsSheet: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundColor(.purple)

                Text("Your Stoic Journey")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                if aiInsights.isEmpty {
                    ProgressView()
                    Text("Marcus is studying your patterns...")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                } else {
                    Text(aiInsights)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple.opacity(0.15))
                        )
                }

                Button("Done") {
                    showingInsights = false
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.purple)
            }
            .padding()
        }
    }

    private func generateAIInsights() async {
        await MainActor.run {
            isLoadingInsights = true
            aiInsights = ""
            showingInsights = true
        }
        
        let llmService = LLMServiceFactory.createService()
        
        // Prepare journal summary
        let recentEntries = manager.entries.suffix(7)
        let moodSummary = recentEntries.compactMap { $0.mood?.rawValue }.joined(separator: ", ")
        let contentSummary = recentEntries.map { $0.content }.joined(separator: " | ")
        
        let prompt = """
        You are Marcus Aurelius analyzing a stoic practitioner's journal patterns.
        
        Recent moods: \(moodSummary.isEmpty ? "Not recorded" : moodSummary)
        Recent entries: \(contentSummary.prefix(500))
        Total entries: \(manager.totalEntries)
        Current streak: \(manager.currentStreak) days
        
        Provide a brief (3-4 sentences) stoic analysis:
        1. What patterns do you notice?
        2. What virtue might they focus on?
        3. One piece of personalized wisdom
        
        Be warm, insightful, and speak as Marcus would.
        """
        
        do {
            let response = try await llmService.generateResponse(prompt: prompt)
            await MainActor.run {
                aiInsights = response
                isLoadingInsights = false
            }
        } catch {
            await MainActor.run {
                aiInsights = "Your dedication to self-examination is itself a virtue. Continue this practice, and wisdom will reveal itself in time."
                isLoadingInsights = false
            }
        }
    }

    // MARK: - Recent Entries Section

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)

            ForEach(manager.entries.suffix(5).reversed()) { entry in
                JournalEntryRow(entry: entry)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Entries Yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("Start your stoic journaling practice")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding()
    }

    // MARK: - New Entry Sheet

    private var newEntrySheet: some View {
        VStack(spacing: 12) {
            Text("New Journal Entry")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            // Mood selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(JournalEntry.JournalMood.allCases, id: \.self) { mood in
                        MoodButton(mood: mood, isSelected: selectedMood == mood) {
                            selectedMood = mood
                        }
                    }
                }
            }

            // Text input
            TextField("What's on your mind?", text: $newEntryText, axis: .vertical)
                .font(.system(size: 12))
                .padding(10)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .lineLimit(3...6)

            // Save button
            Button(action: saveEntry) {
                Text("Save")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(newEntryText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(newEntryText.isEmpty)
        }
        .padding()
    }

    // MARK: - Actions

    private func saveEntry() {
        let entry = JournalEntry(content: newEntryText, mood: selectedMood)
        manager.addEntry(entry)
        newEntryText = ""
        selectedMood = nil
        showingNewEntry = false
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let mood = entry.mood {
                    Image(systemName: mood.icon)
                        .font(.system(size: 10))
                        .foregroundColor(mood.color)
                }

                Text(formatDate(entry.date))
                    .font(.system(size: 9))
                    .foregroundColor(.gray)

                Spacer()
            }

            Text(entry.content)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: JournalEntry.JournalMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mood.icon)
                    .font(.system(size: 16))
                Text(mood.rawValue)
                    .font(.system(size: 8))
            }
            .foregroundColor(isSelected ? mood.color : .gray)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.black.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        JournalView()
    }
}
