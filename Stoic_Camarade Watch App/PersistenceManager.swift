//
//  PersistenceManager.swift
//  StoicCamarade Watch App
//
//  Handles persistence for favorites, history, and effectiveness tracking
//

import Foundation
import SwiftUI
import Combine

// MARK: - Quote History Entry

struct QuoteHistoryEntry: Codable, Identifiable {
    let id: UUID
    let quoteId: String
    let timestamp: Date
    let context: String
    let heartRate: Double?
    var helpful: Bool?  // User feedback: was this quote helpful?
    var heartRateAfter: Double?  // HR after viewing (for effectiveness tracking)

    init(quoteId: String, context: String, heartRate: Double?) {
        self.id = UUID()
        self.quoteId = quoteId
        self.timestamp = Date()
        self.context = context
        self.heartRate = heartRate
        self.helpful = nil
        self.heartRateAfter = nil
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var morningEnabled: Bool
    var morningTime: Date
    var eveningEnabled: Bool
    var eveningTime: Date
    var customEnabled: Bool
    var customTimes: [Date]

    static var `default`: NotificationSettings {
        let calendar = Calendar.current
        let morning = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

        return NotificationSettings(
            morningEnabled: true,
            morningTime: morning,
            eveningEnabled: true,
            eveningTime: evening,
            customEnabled: false,
            customTimes: []
        )
    }
}

// MARK: - Statistics

struct QuoteStatistics: Codable {
    var totalQuotesViewed: Int
    var favoritesCount: Int
    var helpfulCount: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastViewedDate: Date?
    var quotesPerAuthor: [String: Int]
    var effectiveQuotes: [String: Int]  // Quote ID -> helpful count

    static var empty: QuoteStatistics {
        QuoteStatistics(
            totalQuotesViewed: 0,
            favoritesCount: 0,
            helpfulCount: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastViewedDate: nil,
            quotesPerAuthor: [:],
            effectiveQuotes: [:]
        )
    }
}

// MARK: - Persistence Manager

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()

    // Published properties for UI binding
    @Published var favorites: Set<String> = []  // Quote IDs
    @Published var history: [QuoteHistoryEntry] = []
    @Published var statistics: QuoteStatistics = .empty
    @Published var notificationSettings: NotificationSettings = .default

    // UserDefaults keys
    private let favoritesKey = "stoic_favorites"
    private let historyKey = "stoic_history"
    private let statisticsKey = "stoic_statistics"
    private let notificationSettingsKey = "stoic_notification_settings"

    private init() {
        loadAll()
    }

    // MARK: - Load/Save

    private func loadAll() {
        loadFavorites()
        loadHistory()
        loadStatistics()
        loadNotificationSettings()
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favorites = decoded
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([QuoteHistoryEntry].self, from: data) {
            history = decoded
        }
    }

    private func saveHistory() {
        // Keep only last 100 entries to save space
        let trimmedHistory = Array(history.suffix(100))
        if let encoded = try? JSONEncoder().encode(trimmedHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let decoded = try? JSONDecoder().decode(QuoteStatistics.self, from: data) {
            statistics = decoded
        }
    }

    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statisticsKey)
        }
    }

    private func loadNotificationSettings() {
        if let data = UserDefaults.standard.data(forKey: notificationSettingsKey),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = decoded
        }
    }

    func saveNotificationSettings() {
        if let encoded = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(encoded, forKey: notificationSettingsKey)
        }
    }

    // MARK: - Favorites Management

    func isFavorite(_ quoteId: String) -> Bool {
        favorites.contains(quoteId)
    }

    func toggleFavorite(_ quoteId: String) {
        if favorites.contains(quoteId) {
            favorites.remove(quoteId)
            statistics.favoritesCount = max(0, statistics.favoritesCount - 1)
        } else {
            favorites.insert(quoteId)
            statistics.favoritesCount += 1
        }
        saveFavorites()
        saveStatistics()
    }

    func addFavorite(_ quoteId: String) {
        guard !favorites.contains(quoteId) else { return }
        favorites.insert(quoteId)
        statistics.favoritesCount += 1
        saveFavorites()
        saveStatistics()
    }

    func removeFavorite(_ quoteId: String) {
        guard favorites.contains(quoteId) else { return }
        favorites.remove(quoteId)
        statistics.favoritesCount = max(0, statistics.favoritesCount - 1)
        saveFavorites()
        saveStatistics()
    }

    // MARK: - History Management

    func recordQuoteView(quote: StoicQuote, context: HealthContext) {
        let entry = QuoteHistoryEntry(
            quoteId: quote.id,
            context: context.primaryContext,
            heartRate: context.heartRate
        )
        history.append(entry)

        // Update statistics
        statistics.totalQuotesViewed += 1
        statistics.quotesPerAuthor[quote.author, default: 0] += 1

        // Update streak
        updateStreak()

        saveHistory()
        saveStatistics()
    }

    func markQuoteHelpful(entryId: UUID, helpful: Bool, heartRateAfter: Double? = nil) {
        guard let index = history.firstIndex(where: { $0.id == entryId }) else { return }

        history[index].helpful = helpful
        history[index].heartRateAfter = heartRateAfter

        if helpful {
            statistics.helpfulCount += 1
            statistics.effectiveQuotes[history[index].quoteId, default: 0] += 1
        }

        saveHistory()
        saveStatistics()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = statistics.lastViewedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                statistics.currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                statistics.currentStreak = 1
            }
            // If same day (daysDiff == 0), don't change streak
        } else {
            statistics.currentStreak = 1
        }

        statistics.longestStreak = max(statistics.longestStreak, statistics.currentStreak)
        statistics.lastViewedDate = Date()
    }

    // MARK: - Analytics

    func getMostEffectiveQuotes(limit: Int = 5) -> [String] {
        return statistics.effectiveQuotes
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    func getRecentHistory(limit: Int = 20) -> [QuoteHistoryEntry] {
        return Array(history.suffix(limit).reversed())
    }

    func getHistoryForToday() -> [QuoteHistoryEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return history.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }

    // MARK: - Reset

    func resetAllData() {
        favorites = []
        history = []
        statistics = .empty
        notificationSettings = .default

        UserDefaults.standard.removeObject(forKey: favoritesKey)
        UserDefaults.standard.removeObject(forKey: historyKey)
        UserDefaults.standard.removeObject(forKey: statisticsKey)
        UserDefaults.standard.removeObject(forKey: notificationSettingsKey)
    }
}

// MARK: - User Profile & Dynamic Context (Merged)

struct UserProfile: Codable, Equatable {
    var name: String
    var profession: Profession
    var currentFocus: StoicFocus
    var lifeContext: [LifeContext]
    var stoicGoals: [StoicGoal]
    var preferredPhilosopher: PreferredPhilosopher
    var onboardingCompleted: Bool

    var contextSummary: String {
        var parts: [String] = []
        parts.append("a \(profession.displayName)")
        if !lifeContext.isEmpty {
            let contexts = lifeContext.map { $0.displayName }.joined(separator: ", ")
            parts.append("who is \(contexts)")
        }
        parts.append("currently working on \(currentFocus.displayName)")
        if !stoicGoals.isEmpty {
            let goals = stoicGoals.map { $0.displayName }.joined(separator: " and ")
            parts.append("seeking to develop \(goals)")
        }
        return parts.joined(separator: ", ")
    }

    var briefContext: String {
        "\(profession.displayName) working on \(currentFocus.displayName)"
    }

    static let empty = UserProfile(
        name: "",
        profession: .other,
        currentFocus: .generalWisdom,
        lifeContext: [],
        stoicGoals: [],
        preferredPhilosopher: .marcus,
        onboardingCompleted: false
    )
}

enum Profession: String, Codable, CaseIterable {
    case healthcare = "healthcare", business = "business", technology = "technology", education = "education", creative = "creative", legal = "legal", military = "military", publicService = "public_service", student = "student", parent = "parent", retired = "retired", other = "other"
    var displayName: String {
        switch self {
        case .healthcare: return "healthcare professional"
        case .business: return "business professional"
        case .technology: return "tech worker"
        case .education: return "educator"
        case .creative: return "creative professional"
        case .legal: return "legal professional"
        case .military: return "military/veteran"
        case .publicService: return "public servant"
        case .student: return "student"
        case .parent: return "full-time parent"
        case .retired: return "retiree"
        case .other: return "professional"
        }
    }
    var icon: String {
        switch self {
        case .healthcare: return "cross.case.fill"
        case .business: return "briefcase.fill"
        case .technology: return "laptopcomputer"
        case .education: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .legal: return "scale.3d"
        case .military: return "shield.fill"
        case .publicService: return "building.columns.fill"
        case .student: return "graduationcap.fill"
        case .parent: return "house.fill"
        case .retired: return "sun.horizon.fill"
        case .other: return "person.fill"
        }
    }
    var relevantThemes: [String] {
        switch self {
        case .healthcare: return ["accepting outcomes you cannot control", "compassionate detachment", "suffering and death", "service meaning"]
        case .business: return ["managing uncertainty", "virtuous leadership", "pressure", "ambition balance"]
        case .technology: return ["information overload", "rapid change", "meaningful work", "boundaries"]
        default: return ["general resilience", "emotional regulation", "finding meaning", "living virtuously"]
        }
    }
}

enum StoicFocus: String, Codable, CaseIterable {
    case anxiety = "anxiety", anger = "anger", burnout = "burnout", grief = "grief", fear = "fear", procrastination = "procrastination", relationships = "relationships", majorChange = "major_change", healthIssues = "health_issues", workStress = "work_stress", generalWisdom = "general_wisdom"
    var displayName: String {
        switch self {
        case .anxiety: return "managing anxiety"
        case .generalWisdom: return "general growth"
        default: return self.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }
    var stoicTeachings: [String] { ["premeditatio malorum", "dichotomy of control", "present focus"] }
}

enum LifeContext: String, Codable, CaseIterable {
    case newParent = "new_parent", caregiver = "caregiver", recentlyDivorced = "divorced", newJob = "new_job", jobLoss = "job_loss", financialStress = "financial", chronicallyIll = "chronic_illness", inRecovery = "recovery"
    var displayName: String { self.rawValue.replacingOccurrences(of: "_", with: " ") }
    var icon: String {
        switch self {
        case .newParent: return "person.2.fill"
        case .caregiver: return "hand.raised.fill"
        case .recentlyDivorced: return "heart.broken.fill"
        case .newJob: return "briefcase.fill"
        case .jobLoss: return "xmark.circle.fill"
        case .financialStress: return "banknote.fill"
        case .chronicallyIll: return "bandage.fill"
        case .inRecovery: return "heart.fill"
        }
    }
}

enum StoicGoal: String, Codable, CaseIterable {
    case temperance = "temperance", courage = "courage", wisdom = "wisdom", justice = "justice", resilience = "resilience", presence = "presence", acceptance = "acceptance", discipline = "discipline"
    var displayName: String { self.rawValue }
    var icon: String {
        switch self {
        case .temperance: return "drop.fill"
        case .courage: return "shield.fill"
        case .wisdom: return "sparkles"
        case .justice: return "scale.3d"
        case .resilience: return "mountain.2.fill"
        case .presence: return "eye.fill"
        case .acceptance: return "hand.thumbsup.fill"
        case .discipline: return "timer"
        }
    }
}

enum PreferredPhilosopher: String, Codable, CaseIterable {
    case marcus = "marcus", seneca = "seneca", epictetus = "epictetus", noPreference = "no_preference"
    var displayName: String { self.rawValue.capitalized }
    var voiceDescription: String { "wisdom of the Stoics" }
    var description: String {
        switch self {
        case .marcus: return "The Roman Emperor who wrote 'Meditations'."
        case .seneca: return "A statesman focused on practical ethics."
        case .epictetus: return "A former slave who taught control of thoughts."
        case .noPreference: return "A balanced selection of Stoic wisdom."
        }
    }
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    @Published var profile: UserProfile { didSet { save() } }
    private let key = "stoic_user_profile"

    var needsOnboarding: Bool {
        return !profile.onboardingCompleted
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) { self.profile = decoded } else { self.profile = .empty }
    }
    func save() { if let encoded = try? JSONEncoder().encode(profile) { UserDefaults.standard.set(encoded, forKey: key) } }
}

struct DynamicContext: Codable, Equatable {
    var lastUpdated: Date
    var currentMoodTrend: MoodTrend
    var recentThemes: [String]
    var urgentChallenges: [String]
    var growthAreas: [String]
    var recentWins: [String]
    var aiSummary: String
    var suggestedFocus: String
    var philosopherRecommendation: String
    var promptContext: String { "Current mood: \(currentMoodTrend.description)" }
    static let empty = DynamicContext(lastUpdated: .distantPast, currentMoodTrend: .neutral, recentThemes: [], urgentChallenges: [], growthAreas: [], recentWins: [], aiSummary: "", suggestedFocus: "", philosopherRecommendation: "")
}

enum MoodTrend: String, Codable, CaseIterable {
    case improving, stable, struggling, anxious, overwhelmed, neutral, peaceful, grateful
    var description: String { self.rawValue }
    var stoicApproach: String { "Focus on virtue." }
}

class DynamicUserContextManager: ObservableObject {
    static let shared = DynamicUserContextManager()
    @Published var dynamicContext: DynamicContext { didSet { save() } }
    private let contextKey = "stoic_dynamic_context"
    
    var needsRefresh: Bool {
        let sixHours: TimeInterval = 6 * 60 * 60
        return Date().timeIntervalSince(dynamicContext.lastUpdated) > sixHours
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: contextKey), let decoded = try? JSONDecoder().decode(DynamicContext.self, from: data) { self.dynamicContext = decoded } else { self.dynamicContext = .empty }
    }
    private func save() { if let encoded = try? JSONEncoder().encode(dynamicContext) { UserDefaults.standard.set(encoded, forKey: contextKey) } }
    
    func refreshContextWithAI(profile: UserProfile, journalManager: JournalManager) async {
        // This would normally call an AI service to summarize the user's state
        // For now, we update the timestamp to prevent constant refresh calls
        await MainActor.run {
            var updated = dynamicContext
            updated.lastUpdated = Date()
            dynamicContext = updated
        }
    }
    
    func generateFullContext(profile: UserProfile, journalManager: JournalManager) -> String { return "Context summary for \(profile.name)" }
}
