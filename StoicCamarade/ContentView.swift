//
//  ContentView.swift
//  StoicCompanion WatchKit Extension
//
//  A context-aware stoic wisdom companion for Apple Watch
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthDataManager()
    @StateObject private var quoteManager = QuoteManager()
    @State private var currentQuote: StoicQuote?
    @State private var isLoading = false
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Stoic logo/icon
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if let quote = currentQuote {
                        VStack(spacing: 12) {
                            // Quote text
                            Text(quote.text)
                                .font(.system(size: 14, weight: .regular, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                            
                            // Author
                            Text("— \(quote.author)")
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundColor(.orange)
                            
                            // Book reference
                            Text(quote.book)
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 4)
                            
                            // Context info
                            if let context = healthManager.currentContext {
                                HStack(spacing: 4) {
                                    Image(systemName: contextIcon(for: context))
                                        .font(.system(size: 10))
                                    Text(contextDescription(for: context))
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                    } else {
                        Text("Tap to receive wisdom")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    // Action button
                    Button(action: {
                        Task {
                            await fetchNewQuote()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New Wisdom")
                        }
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
            .navigationTitle("Stoic")
        }
        .onAppear {
            Task {
                await healthManager.requestAuthorization()
                await fetchNewQuote()
            }
        }
    }
    
    private func fetchNewQuote() async {
        isLoading = true
        
        // Get current health context
        let context = await healthManager.getCurrentContext()
        
        // Get appropriate quote from Claude
        let quote = await quoteManager.getContextualQuote(context: context)
        
        await MainActor.run {
            currentQuote = quote
            isLoading = false
        }
    }
    
    private func contextIcon(for context: HealthContext) -> String {
        switch context.primaryContext {
        case "stress", "anxiety":
            return "heart.fill"
        case "morning":
            return "sunrise.fill"
        case "evening":
            return "moon.fill"
        case "active":
            return "figure.walk"
        default:
            return "circle.fill"
        }
    }
    
    private func contextDescription(for context: HealthContext) -> String {
        var parts: [String] = []
        
        if let hr = context.heartRate {
            parts.append("♥️ \(Int(hr))")
        }
        
        if let timeDesc = context.timeOfDay {
            parts.append(timeDesc.capitalized)
        }
        
        return parts.joined(separator: " • ")
    }
}

// MARK: - Models

struct StoicQuote: Codable, Identifiable {
    let id: String
    let text: String
    let author: String
    let book: String
    let contexts: [String]
    let heartRateContext: String?
    let timeOfDay: String?
    let activityContext: String?
}

struct HealthContext {
    var heartRate: Double?
    var heartRateVariability: Double?
    var activeCalories: Double?
    var steps: Int?
    var timeOfDay: String?
    var isActive: Bool
    var stressLevel: StressLevel
    var primaryContext: String
    
    enum StressLevel {
        case low, normal, elevated, high
    }
}

// MARK: - Health Data Manager

class HealthDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var currentContext: HealthContext?
    
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    func requestAuthorization() async {
        let typesToRead: Set<HKObjectType> = [
            heartRateType,
            hrvType!,
            activeEnergyType,
            stepType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    func getCurrentContext() async -> HealthContext {
        let heartRate = await getLatestHeartRate()
        let hrv = await getLatestHRV()
        let calories = await getTodayActiveCalories()
        let steps = await getTodaySteps()
        let timeOfDay = getTimeOfDay()
        
        // Determine stress level based on HR and HRV
        let stressLevel = determineStressLevel(heartRate: heartRate, hrv: hrv)
        
        // Determine if currently active
        let isActive = (calories ?? 0) > 100 // Simple heuristic
        
        // Determine primary context
        let primaryContext = determinePrimaryContext(
            stressLevel: stressLevel,
            timeOfDay: timeOfDay,
            isActive: isActive
        )
        
        let context = HealthContext(
            heartRate: heartRate,
            heartRateVariability: hrv,
            activeCalories: calories,
            steps: steps,
            timeOfDay: timeOfDay,
            isActive: isActive,
            stressLevel: stressLevel,
            primaryContext: primaryContext
        )
        
        await MainActor.run {
            self.currentContext = context
        }
        
        return context
    }
    
    private func getLatestHeartRate() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            healthStore.execute(query)
        }
    }
    
    private func getLatestHRV() async -> Double? {
        guard let hrvType = hrvType else { return nil }
        
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }
            healthStore.execute(query)
        }
    }
    
    private func getTodayActiveCalories() async -> Double? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let calories = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }
    
    private func getTodaySteps() async -> Int? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let steps = Int(sum.doubleValue(for: .count()))
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<21:
            return "evening"
        default:
            return "night"
        }
    }
    
    private func determineStressLevel(heartRate: Double?, hrv: Double?) -> HealthContext.StressLevel {
        // Simple heuristic - in production, you'd want more sophisticated analysis
        guard let hr = heartRate else { return .normal }
        
        if hr > 100 {
            return .elevated
        } else if hr > 110 {
            return .high
        } else if hr < 60 {
            return .low
        } else {
            return .normal
        }
    }
    
    private func determinePrimaryContext(stressLevel: HealthContext.StressLevel, timeOfDay: String, isActive: Bool) -> String {
        // Priority-based context determination
        if stressLevel == .elevated || stressLevel == .high {
            return "stress"
        }
        
        if timeOfDay == "morning" {
            return "morning"
        }
        
        if timeOfDay == "evening" || timeOfDay == "night" {
            return "evening"
        }
        
        if isActive {
            return "active"
        }
        
        return "general"
    }
}

// MARK: - Quote Manager

class QuoteManager: ObservableObject {
    private var allQuotes: [StoicQuote] = []
    private let llmService: LLMService

    init() {
        // Create LLM service using factory
        self.llmService = LLMServiceFactory.createService()
        loadQuotes()
    }

    private func loadQuotes() {
        // Load quotes from StoicQuotes.json
        guard let url = Bundle.main.url(forResource: "StoicQuotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(QuoteDatabase.self, from: data) else {
            print("⚠️ Failed to load quotes from bundle")
            // Use fallback quotes
            loadFallbackQuotes()
            return
        }
        allQuotes = decoded.quotes
    }

    private func loadFallbackQuotes() {
        // Fallback quotes in case JSON loading fails
        allQuotes = [
            StoicQuote(
                id: "ma_001",
                text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
                author: "Marcus Aurelius",
                book: "Meditations",
                contexts: ["stress", "control"],
                heartRateContext: "elevated",
                timeOfDay: "any",
                activityContext: nil
            ),
            StoicQuote(
                id: "ep_001",
                text: "First say to yourself what you would be; and then do what you have to do.",
                author: "Epictetus",
                book: "Discourses",
                contexts: ["morning", "action"],
                heartRateContext: "resting",
                timeOfDay: "morning",
                activityContext: nil
            )
        ]
    }

    func getContextualQuote(context: HealthContext) async -> StoicQuote {
        // If LLM API is disabled, use local selection
        guard Config.useLLMAPI else {
            return selectLocalQuote(for: context)
        }

        // Try to use LLM service
        do {
            let quote = try await llmService.selectQuote(
                context: context,
                availableQuotes: allQuotes
            )

            if Config.debugMode {
                print("✅ \(Config.llmProvider.displayName) selected: \(quote.id)")
            }

            return quote
        } catch {
            if Config.debugMode {
                print("⚠️ LLM API failed: \(error.localizedDescription)")
                print("Using local fallback selection")
            }

            // Fallback to local selection
            return selectLocalQuote(for: context)
        }
    }

    private func selectLocalQuote(for context: HealthContext) -> StoicQuote {
        // Local fallback logic when API fails or is disabled
        let filtered = allQuotes.filter { quote in
            var matches = false

            // Match on time of day
            if let timeOfDay = context.timeOfDay,
               let quoteTime = quote.timeOfDay,
               (quoteTime == timeOfDay || quoteTime == "any") {
                matches = true
            }

            // Match on context
            if quote.contexts.contains(context.primaryContext) {
                matches = true
            }

            // Match on stress/heart rate
            if context.stressLevel == .elevated || context.stressLevel == .high {
                if quote.heartRateContext == "elevated" {
                    matches = true
                }
            }

            return matches
        }

        // Return random from filtered, or random from all if no matches
        return filtered.randomElement() ?? allQuotes.randomElement() ?? allQuotes[0]
    }
}

// MARK: - Quote Database Model

struct QuoteDatabase: Codable {
    let quotes: [StoicQuote]
}

#Preview {
    ContentView()
}
