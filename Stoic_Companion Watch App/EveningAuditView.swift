//
//  EveningAuditView.swift
//  StoicCompanion Watch App
//
//  Evening reflection and daily audit inspired by Seneca
//

import SwiftUI
import Combine

// MARK: - Audit Entry Model

struct AuditEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var wentWell: String
    var couldImprove: String
    var gratitude: String
    var tomorrowFocus: String

    init() {
        self.id = UUID()
        self.date = Date()
        self.wentWell = ""
        self.couldImprove = ""
        self.gratitude = ""
        self.tomorrowFocus = ""
    }
}

// MARK: - Audit Manager

class AuditManager: ObservableObject {
    static let shared = AuditManager()

    @Published var entries: [AuditEntry] = []
    @Published var currentEntry: AuditEntry?

    private let entriesKey = "stoic_audit_entries"

    init() {
        loadEntries()
        checkTodayEntry()
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([AuditEntry].self, from: data) {
            // Keep only last 30 entries
            entries = Array(decoded.suffix(30))
        }
    }

    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }

    func checkTodayEntry() {
        let calendar = Calendar.current
        if let existing = entries.first(where: { calendar.isDateInToday($0.date) }) {
            currentEntry = existing
        } else {
            currentEntry = AuditEntry()
        }
    }

    func saveCurrentEntry() {
        guard var entry = currentEntry else { return }

        let calendar = Calendar.current
        // Remove any existing entry for today
        entries.removeAll { calendar.isDateInToday($0.date) }

        // Add current entry
        entries.append(entry)

        saveEntries()
    }

    func hasCompletedToday() -> Bool {
        guard let entry = currentEntry else { return false }
        return !entry.wentWell.isEmpty || !entry.couldImprove.isEmpty
    }

    func getAuditStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Evening Audit View

struct EveningAuditView: View {
    @ObservedObject private var manager = AuditManager.shared
    @State private var currentStep = 0
    @State private var showingCompletion = false

    private let steps = ["Welcome", "Went Well", "Improve", "Gratitude", "Tomorrow"]

    var body: some View {
        Group {
            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                wentWellStep
            case 2:
                improveStep
            case 3:
                gratitudeStep
            case 4:
                tomorrowStep
            default:
                completionStep
            }
        }
        .navigationTitle("Evening Audit")
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            Text("Evening Audit Ready.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("\"I will keep constant watch over myself and review each day.\"")
                .font(.system(size: 11, design: .serif))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .italic()

            Text("— Seneca")
                .font(.system(size: 10))
                .foregroundColor(.purple)

            Button(action: { withAnimation { currentStep = 1 } }) {
                Text("Tap to start.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }

    // MARK: - Went Well Step

    private var wentWellStep: some View {
        VStack(spacing: 16) {
            ProgressDots(current: 1, total: 4)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)

            Text("What went well today?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("I did well at...", text: Binding(
                get: { manager.currentEntry?.wentWell ?? "" },
                set: { manager.currentEntry?.wentWell = $0 }
            ))
            .font(.system(size: 12))
            .padding(10)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)

            navigationButtons(back: 0, next: 2)
        }
        .padding()
    }

    // MARK: - Improve Step

    private var improveStep: some View {
        VStack(spacing: 16) {
            ProgressDots(current: 2, total: 4)

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.orange)

            Text("What could you improve?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("Tomorrow I will...", text: Binding(
                get: { manager.currentEntry?.couldImprove ?? "" },
                set: { manager.currentEntry?.couldImprove = $0 }
            ))
            .font(.system(size: 12))
            .padding(10)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)

            navigationButtons(back: 1, next: 3)
        }
        .padding()
    }

    // MARK: - Gratitude Step

    private var gratitudeStep: some View {
        VStack(spacing: 16) {
            ProgressDots(current: 3, total: 4)

            Image(systemName: "heart.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)

            Text("What are you grateful for?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("I'm grateful for...", text: Binding(
                get: { manager.currentEntry?.gratitude ?? "" },
                set: { manager.currentEntry?.gratitude = $0 }
            ))
            .font(.system(size: 12))
            .padding(10)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)

            navigationButtons(back: 2, next: 4)
        }
        .padding()
    }

    // MARK: - Tomorrow Step

    private var tomorrowStep: some View {
        VStack(spacing: 16) {
            ProgressDots(current: 4, total: 4)

            Image(systemName: "sunrise.fill")
                .font(.system(size: 30))
                .foregroundColor(.yellow)

            Text("Tomorrow's focus?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("I will focus on...", text: Binding(
                get: { manager.currentEntry?.tomorrowFocus ?? "" },
                set: { manager.currentEntry?.tomorrowFocus = $0 }
            ))
            .font(.system(size: 12))
            .padding(10)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button(action: { withAnimation { currentStep = 3 } }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    manager.saveCurrentEntry()
                    withAnimation { currentStep = 5 }
                }) {
                    Text("Complete")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }

    // MARK: - Completion Step

    private var completionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Audit Complete")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // AI-generated wisdom based on audit
            if isLoadingWisdom {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Marcus is reflecting...")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            } else if let wisdom = aiWisdom {
                Text(wisdom)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.orange)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
            }

            // Streak display
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(manager.getAuditStreak()) day streak")
                    .foregroundColor(.orange)
            }
            .font(.system(size: 12, weight: .medium))

            Text("Rest well. Tomorrow awaits.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding()
        .onAppear {
            Task {
                await generateAIWisdom()
            }
        }
    }

    // MARK: - AI Wisdom Generation

    @State private var aiWisdom: String?
    @State private var isLoadingWisdom = false

    private func generateAIWisdom() async {
        guard let entry = manager.currentEntry else { return }
        
        await MainActor.run { isLoadingWisdom = true }
        
        let llmService = LLMServiceFactory.createService()
        
        let prompt = """
        You are Marcus Aurelius. A practitioner has completed their evening audit:
        - What went well: \(entry.wentWell)
        - What to improve: \(entry.couldImprove)
        - Grateful for: \(entry.gratitude)
        - Tomorrow's focus: \(entry.tomorrowFocus)
        
        Give them ONE sentence of personalized stoic wisdom for a restful night. Be warm and encouraging.
        """
        
        do {
            let response = try await llmService.generateResponse(prompt: prompt)
            await MainActor.run {
                aiWisdom = response
                isLoadingWisdom = false
            }
        } catch {
            await MainActor.run {
                aiWisdom = "Rest now. You examined your day - that is wisdom in action."
                isLoadingWisdom = false
            }
        }
    }

    // MARK: - Navigation Buttons

    private func navigationButtons(back: Int, next: Int) -> some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation { currentStep = back } }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { withAnimation { currentStep = next } }) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Progress Dots

struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    NavigationView {
        EveningAuditView()
    }
}
