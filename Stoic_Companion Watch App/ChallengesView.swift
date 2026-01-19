//
//  ChallengesView.swift
//  StoicCompanion Watch App
//
//  Daily Stoic Challenges with streak tracking
//

import SwiftUI
import Combine

// MARK: - Challenge Model

struct StoicChallenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: ChallengeCategory
    let difficulty: ChallengeDifficulty
    let icon: String

    enum ChallengeCategory: String, Codable, CaseIterable {
        case discipline = "Discipline"
        case discomfort = "Discomfort"
        case mindfulness = "Mindfulness"
        case virtue = "Virtue"
        case social = "Social"
    }

    enum ChallengeDifficulty: String, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
}

struct ChallengeCompletion: Codable, Identifiable {
    let id: UUID
    let challengeId: String
    let completedAt: Date
    var reflection: String?

    init(challengeId: String, reflection: String? = nil) {
        self.id = UUID()
        self.challengeId = challengeId
        self.completedAt = Date()
        self.reflection = reflection
    }
}

// MARK: - Challenge Manager

class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()

    @Published var currentChallenge: StoicChallenge?
    @Published var completions: [ChallengeCompletion] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    private let completionsKey = "stoic_challenge_completions"
    private let streakKey = "stoic_challenge_streak"
    private let longestStreakKey = "stoic_challenge_longest_streak"
    private let lastChallengeKey = "stoic_last_challenge_date"

    // Available challenges
    let challenges: [StoicChallenge] = [
        // Discipline
        StoicChallenge(id: "cold_shower", title: "Cold Shower Only", description: "Take only cold showers today. Embrace discomfort.", category: .discomfort, difficulty: .hard, icon: "drop.fill"),
        StoicChallenge(id: "no_complain", title: "No Complaints", description: "Go the entire day without complaining about anything.", category: .discipline, difficulty: .medium, icon: "xmark.circle.fill"),
        StoicChallenge(id: "early_rise", title: "Rise Early", description: "Wake up 1 hour earlier than usual.", category: .discipline, difficulty: .medium, icon: "sunrise.fill"),
        StoicChallenge(id: "digital_fast", title: "Digital Fast", description: "No social media or entertainment apps today.", category: .discipline, difficulty: .hard, icon: "iphone.slash"),
        StoicChallenge(id: "simple_meal", title: "Simple Meal", description: "Eat only plain, simple food today.", category: .discomfort, difficulty: .easy, icon: "leaf.fill"),

        // Mindfulness
        StoicChallenge(id: "morning_pages", title: "Morning Pages", description: "Write 3 pages of stream-of-consciousness first thing.", category: .mindfulness, difficulty: .medium, icon: "pencil.line"),
        StoicChallenge(id: "hourly_pause", title: "Hourly Pause", description: "Every hour, stop and take 3 deep breaths.", category: .mindfulness, difficulty: .easy, icon: "clock.fill"),
        StoicChallenge(id: "present_moment", title: "Present Moment", description: "When you catch yourself worrying, return to now.", category: .mindfulness, difficulty: .medium, icon: "sun.max.fill"),
        StoicChallenge(id: "gratitude_3", title: "Gratitude Three", description: "Write down 3 things you're grateful for.", category: .mindfulness, difficulty: .easy, icon: "heart.fill"),

        // Virtue
        StoicChallenge(id: "help_stranger", title: "Help a Stranger", description: "Perform an act of kindness for someone you don't know.", category: .virtue, difficulty: .medium, icon: "hand.raised.fill"),
        StoicChallenge(id: "speak_truth", title: "Radical Truth", description: "Be completely honest in all interactions today.", category: .virtue, difficulty: .hard, icon: "checkmark.seal.fill"),
        StoicChallenge(id: "listen_fully", title: "Full Listening", description: "In every conversation, listen without planning your response.", category: .virtue, difficulty: .medium, icon: "ear.fill"),
        StoicChallenge(id: "forgive_one", title: "Forgive One", description: "Consciously forgive someone who wronged you.", category: .virtue, difficulty: .hard, icon: "hands.sparkles.fill"),

        // Social
        StoicChallenge(id: "no_gossip", title: "No Gossip", description: "Speak of others only if they were present.", category: .social, difficulty: .medium, icon: "person.2.slash.fill"),
        StoicChallenge(id: "genuine_interest", title: "Genuine Interest", description: "Ask deep questions and truly care about answers.", category: .social, difficulty: .easy, icon: "questionmark.circle.fill"),

        // Discomfort
        StoicChallenge(id: "fast_meal", title: "Skip a Meal", description: "Practice voluntary hunger. Skip one meal today.", category: .discomfort, difficulty: .medium, icon: "fork.knife"),
        StoicChallenge(id: "hard_floor", title: "Sleep on Floor", description: "Sleep on the hard floor tonight.", category: .discomfort, difficulty: .hard, icon: "bed.double.fill"),
        StoicChallenge(id: "walk_weather", title: "Walk in Weather", description: "Take a 20-minute walk regardless of weather.", category: .discomfort, difficulty: .medium, icon: "cloud.rain.fill"),
    ]

    init() {
        loadData()
        selectDailyChallenge()
    }

    private func loadData() {
        // Load completions
        if let data = UserDefaults.standard.data(forKey: completionsKey),
           let decoded = try? JSONDecoder().decode([ChallengeCompletion].self, from: data) {
            completions = decoded
        }

        // Load streaks
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)

        // Update streak based on completions
        updateStreak()
    }

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(completions) {
            UserDefaults.standard.set(encoded, forKey: completionsKey)
        }
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
    }

    func selectDailyChallenge() {
        // Use date as seed for consistent daily challenge
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = day % challenges.count
        currentChallenge = challenges[index]
    }

    func completeChallenge(reflection: String? = nil) {
        guard let challenge = currentChallenge else { return }

        let completion = ChallengeCompletion(challengeId: challenge.id, reflection: reflection)
        completions.append(completion)

        // Update streak
        updateStreak()

        // Save
        saveData()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if completed today
        let completedToday = completions.contains { calendar.isDateInToday($0.completedAt) }

        if completedToday {
            // Check yesterday
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let completedYesterday = completions.contains {
                calendar.isDate($0.completedAt, inSameDayAs: yesterday)
            }

            if completedYesterday || currentStreak == 0 {
                currentStreak += 1
            }
        } else {
            // Check if we broke the streak
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let completedYesterday = completions.contains {
                calendar.isDate($0.completedAt, inSameDayAs: yesterday)
            }

            if !completedYesterday {
                currentStreak = 0
            }
        }

        longestStreak = max(longestStreak, currentStreak)
    }

    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completions.contains { calendar.isDateInToday($0.completedAt) }
    }

    func getTodayCompletion() -> ChallengeCompletion? {
        let calendar = Calendar.current
        return completions.first { calendar.isDateInToday($0.completedAt) }
    }

    func updateTodayReflection(_ reflection: String) {
        let calendar = Calendar.current
        if let index = completions.firstIndex(where: { calendar.isDateInToday($0.completedAt) }) {
            completions[index].reflection = reflection
            saveData()
        }
    }
}

// MARK: - Challenges View

struct ChallengesView: View {
    @ObservedObject private var manager = ChallengeManager.shared
    @State private var showingCompletion = false
    @State private var showingReflection = false
    @State private var reflectionText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Challenge card
                if let challenge = manager.currentChallenge {
                    challengeCard(challenge)
                }

                // Completion state or action button
                if manager.isCompletedToday() {
                    completedView
                } else {
                    actionButton
                }

                // Streak display
                streakView
            }
            .padding()
        }
        .navigationTitle("Challenge")
        .sheet(isPresented: $showingReflection) {
            reflectionSheet
        }
    }

    // MARK: - Challenge Card

    private func challengeCard(_ challenge: StoicChallenge) -> some View {
        VStack(spacing: 12) {
            // Icon with fire background
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: challenge.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
            }

            // Title
            Text("Challenge:")
                .font(.system(size: 11))
                .foregroundColor(.gray)

            Text(challenge.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text(challenge.description)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            // Difficulty badge
            HStack(spacing: 4) {
                Image(systemName: difficultyIcon(challenge.difficulty))
                    .font(.system(size: 10))
                Text(challenge.difficulty.rawValue)
                    .font(.system(size: 10))
            }
            .foregroundColor(difficultyColor(challenge.difficulty))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(difficultyColor(challenge.difficulty).opacity(0.2))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
        )
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("Completed!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("Streak: \(manager.currentStreak)")
                .font(.system(size: 12))
                .foregroundColor(.orange)

            // Reflect button
            Button(action: { showingReflection = true }) {
                Text("Reflect?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: {
            withAnimation {
                manager.completeChallenge()
                showingReflection = true
            }
        }) {
            HStack {
                Image(systemName: "checkmark")
                Text("Mark Complete")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Streak View

    private var streakView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                Text("\(manager.currentStreak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("Current")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }

            Divider()
                .frame(height: 40)
                .background(Color.gray.opacity(0.3))

            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                Text("\(manager.longestStreak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("Best")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
        )
    }

    // MARK: - Reflection Sheet

    private var reflectionSheet: some View {
        VStack(spacing: 16) {
            Text("Reflect")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("How did completing this challenge make you feel?")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            TextField("Your reflection...", text: $reflectionText)
                .font(.system(size: 12))
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)

            Button(action: {
                if !reflectionText.isEmpty {
                    manager.updateTodayReflection(reflectionText)
                }
                reflectionText = ""
                showingReflection = false
            }) {
                Text("Save")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }

    // MARK: - Helpers

    private func difficultyIcon(_ difficulty: StoicChallenge.ChallengeDifficulty) -> String {
        switch difficulty {
        case .easy: return "circle"
        case .medium: return "circle.lefthalf.filled"
        case .hard: return "circle.fill"
        }
    }

    private func difficultyColor(_ difficulty: StoicChallenge.ChallengeDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .red
        }
    }
}

#Preview {
    NavigationView {
        ChallengesView()
    }
}
