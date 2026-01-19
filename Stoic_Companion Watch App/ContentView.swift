//
//  ContentView.swift
//  StoicCompanion Watch App
//
//  A context-aware stoic wisdom companion for Apple Watch
//  Part of the Nano Banana Pro Series aesthetic.
//

import SwiftUI
import HealthKit
import Combine
import WatchKit

struct ContentView: View {
    @StateObject private var healthManager = HealthDataManager()
    @StateObject private var quoteManager = QuoteManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var dynamicContextManager = DynamicUserContextManager.shared
    @State private var currentQuote: StoicQuote?
    @State private var quoteImage: UIImage?
    @State private var isLoading = false
    @State private var showingOnboarding = false
    
    // Animation states
    @State private var animateQuote = false

    var body: some View {
        NavigationView {
            ZStack {
                // Nano Banana Pro: Animated Deep Background
                PremiumBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Marcus Avatar & App Title
                        VStack(spacing: 8) {
                            PremiumAssets.MarcusAvatar(size: 80)
                                .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.4), radius: 15)
                            
                            Text("STOIC COMPANION")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                                .tracking(2)
                        }
                        .padding(.top, 10)
                        
                        // Main Quote Section
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(PremiumAssets.Colors.vibrantOrange)
                                Text("CONSULTING THE ANCIENTS...")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 180)
                        } else if let quote = currentQuote {
                            ZStack {
                                // Background Layer: AI Generated Image or Subtle fallback
                                if let uiImage = quoteImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipped()
                                        .opacity(0.4)
                                        .overlay(LinearGradient(colors: [.black, .black.opacity(0.3)], startPoint: .bottom, endPoint: .top))
                                        .cornerRadius(24)
                                } else {
                                    PremiumAssets.GlassBackdrop(cornerRadius: 24, opacity: 0.1)
                                        .frame(height: 200)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(
                                                    LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                
                                // Quote Content
                                VStack(spacing: 14) {
                                    Image(systemName: "quote.opening")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                                    
                                    Text(quote.text)
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .lineSpacing(3)
                                        .minimumScaleFactor(0.8)
                                    
                                    VStack(spacing: 4) {
                                        Text("— \(quote.author.uppercased())")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                                            .tracking(1)
                                        
                                        if let book = quote.book {
                                            Text(book.uppercased())
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundColor(.gray.opacity(0.6))
                                                .tracking(0.5)
                                        }
                                    }
                                    
                                    // Health Context Tag
                                    if let context = healthManager.currentContext {
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(PremiumAssets.Colors.vibrantOrange)
                                                .frame(width: 4, height: 4)
                                            Text(contextDescription(for: context).uppercased())
                                                .font(.system(size: 7, weight: .black))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.white.opacity(0.1)))
                                        .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding()
                            }
                            .scaleEffect(animateQuote ? 1.0 : 0.98)
                            .opacity(animateQuote ? 1 : 0)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        
                        // New Wisdom Action
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            Task { await fetchNewQuote() }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("NEW WISDOM")
                            }
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(PremiumAssets.Colors.vibrantOrange)
                            .cornerRadius(12)
                            .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Navigation Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NavCard(title: "TOOLS", icon: "square.grid.2x2.fill", color: .blue, destination: AnyView(ToolsGridView()))
                            NavCard(title: "STORY", icon: "book.closed.fill", color: .mint, destination: AnyView(PersonalizedStoriesView()))
                            NavCard(title: "MARCUS", icon: "person.bust.fill", color: .orange, destination: AnyView(ConsultMarcusView()))
                            NavCard(title: "SAVED", icon: "heart.fill", color: .red, destination: AnyView(FavoritesView()))
                        }
                        .padding(.top, 10)
                        
                        // Secondary Links
                        VStack(spacing: 8) {
                            NavigationLink(destination: HistoryView()) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("JOURNAL HISTORY")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: SettingsView()) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("SETTINGS")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            if profileManager.needsOnboarding {
                showingOnboarding = true
            }

            Task {
                await healthManager.requestAuthorization()
                
                if dynamicContextManager.needsRefresh {
                    await dynamicContextManager.refreshContextWithAI(
                        profile: profileManager.profile,
                        journalManager: JournalManager.shared
                    )
                }

                if currentQuote == nil {
                    await fetchNewQuote()
                }
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(profileManager: profileManager, isPresented: $showingOnboarding)
        }
    }
    
    private func fetchNewQuote() async {
        withAnimation(.easeOut(duration: 0.3)) {
            animateQuote = false
            isLoading = true
        }

        let context = await healthManager.getCurrentContext()
        let quote = await quoteManager.getContextualQuote(
            context: context,
            profile: profileManager.profile.onboardingCompleted ? profileManager.profile : nil,
            dynamicContext: dynamicContextManager.dynamicContext
        )

        // Generate AI Background Image if Gemini is active
        var image: UIImage? = nil
        if Config.llmProvider == .gemini {
            if let generated = try? await quoteManager.generateBackground(for: quote) {
                image = UIImage(data: generated)
            }
        }

        await MainActor.run {
            currentQuote = quote
            quoteImage = image
            isLoading = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateQuote = true
            }
        }
    }
    
    private func contextIcon(for context: HealthContext) -> String {
        switch context.primaryContext {
        case "stress", "anxiety": return "heart.fill"
        case "morning": return "sunrise.fill"
        case "evening": return "moon.fill"
        case "active": return "figure.walk"
        default: return "circle.fill"
        }
    }
    
    private func contextDescription(for context: HealthContext) -> String {
        var parts: [String] = []
        if let hr = context.heartRate { parts.append("\(Int(hr)) BPM") }
        if let timeDesc = context.timeOfDay { parts.append(timeDesc) }
        return parts.joined(separator: " • ")
    }
}

// MARK: - Navigation Card

struct NavCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(PremiumAssets.GlassBackdrop(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Shared models now in LLMService.swift

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
        
        let stressLevel = determineStressLevel(heartRate: heartRate, hrv: hrv)
        let isActive = (calories ?? 0) > 100 
        
        let primaryContext = determinePrimaryContext(
            stressLevel: stressLevel,
            timeOfDay: timeOfDay,
            isActive: isActive
        )
        
        let context = HealthContext(
            heartRate: heartRate,
            heartRateVariability: hrv,
            timeOfDay: timeOfDay,
            stressLevel: stressLevel,
            isActive: isActive,
            primaryContext: primaryContext,
            activeCalories: calories,
            steps: steps != nil ? Double(steps!) : nil
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
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
    
    private func determineStressLevel(heartRate: Double?, hrv: Double?) -> StressLevel {
        guard let hr = heartRate else { return .normal }
        if hr > 110 { return .high }
        else if hr > 100 { return .elevated }
        else if hr < 60 { return .low }
        else { return .normal }
    }
    
    private func determinePrimaryContext(stressLevel: StressLevel, timeOfDay: String, isActive: Bool) -> String {
        if stressLevel == .elevated || stressLevel == .high { return "stress" }
        if timeOfDay == "morning" { return "morning" }
        if timeOfDay == "evening" || timeOfDay == "night" { return "evening" }
        if isActive { return "active" }
        return "general"
    }
}

// MARK: - Quote Manager

class QuoteManager: ObservableObject {
    private var allQuotes: [StoicQuote] = []
    private let llmService: LLMService
    private let ragService: RAGService
    private var ragAvailable: Bool = true  // Assume available until proven otherwise

    init() {
        self.llmService = LLMServiceFactory.createService()
        self.ragService = RAGService()
        loadQuotes()

        // Check RAG availability in background
        Task {
            ragAvailable = await ragService.checkHealth()
            if Config.debugMode {
                print(ragAvailable ? "🟢 RAG API available" : "🟠 RAG API unavailable, using LLM fallback")
            }
        }
    }

    private func loadQuotes() {
        guard let url = Bundle.main.url(forResource: "StoicQuotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(QuoteDatabase.self, from: data) else {
            loadFallbackQuotes()
            return
        }
        allQuotes = decoded.quotes
    }

    private func loadFallbackQuotes() {
        allQuotes = [
            StoicQuote(id: "ma_001", text: "You have power over your mind - not outside events.", author: "Marcus Aurelius", book: "Meditations", contexts: ["stress"], timeOfDay: "any", heartRateContext: "elevated", activityContext: nil)
        ]
    }

    func getContextualQuote(context: HealthContext, profile: UserProfile?, dynamicContext: DynamicContext?) async -> StoicQuote {
        // Priority 1: RAG API (semantic search with 2,160 passages)
        if Config.useRAGAPI && ragAvailable {
            do {
                let quote = try await ragService.getContextualQuote(context: context)
                if Config.debugMode {
                    print("🎯 RAG: Retrieved quote from \(quote.author)")
                }
                return quote
            } catch {
                if Config.debugMode {
                    print("⚠️ RAG failed: \(error.localizedDescription)")
                }
                // Mark RAG as unavailable for this session
                if Config.ragFallbackToLLM {
                    ragAvailable = false
                }
            }
        }

        // Priority 2: LLM-based selection (if enabled and RAG failed)
        guard Config.useLLMAPI else { return selectLocalQuote(for: context, profile: profile) }
        do {
            // Try enhanced selection if possible
            if let gemini = llmService as? GeminiService {
                 return try await gemini.selectQuote(context: context, availableQuotes: allQuotes)
            }
            return try await llmService.selectQuote(context: context, availableQuotes: allQuotes)
        } catch {
            // Priority 3: Local fallback
            return selectLocalQuote(for: context, profile: profile)
        }
    }
    
    func getQuote(byId id: String) -> StoicQuote? {
        return allQuotes.first(where: { $0.id == id })
    }
    
    func getQuotes(byIds ids: [String]) -> [StoicQuote] {
        return ids.compactMap { getQuote(byId: $0) }
    }
    
    func generateBackground(for quote: StoicQuote) async throws -> Data? {
        guard let gemini = llmService as? GeminiService else { return nil }
        let generated = try await gemini.generateQuoteBackground(quote: quote)
        return generated.data
    }

    private func selectLocalQuote(for context: HealthContext, profile: UserProfile?) -> StoicQuote {
        let filtered = allQuotes.filter { $0.contexts.contains(context.primaryContext) }
        return filtered.randomElement() ?? allQuotes.randomElement()!
    }
}

struct QuoteDatabase: Codable {
    let quotes: [StoicQuote]
}

#Preview {
    ContentView()
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @ObservedObject var profileManager: ProfileManager
    @Binding var isPresented: Bool
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedProfession: Profession = .other
    @State private var selectedFocus: StoicFocus = .generalWisdom
    @State private var selectedContexts: Set<LifeContext> = []
    @State private var selectedGoals: Set<StoicGoal> = []
    @State private var selectedPhilosopher: PreferredPhilosopher = .noPreference
    @State private var userName: String = ""

    var body: some View {
        ZStack {
            // Ambient background
            backgroundGradient

            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(OnboardingStep.welcome)
                nameStep.tag(OnboardingStep.name)
                professionStep.tag(OnboardingStep.profession)
                challengeStep.tag(OnboardingStep.challenge)
                contextStep.tag(OnboardingStep.context)
                goalsStep.tag(OnboardingStep.goals)
                philosopherStep.tag(OnboardingStep.philosopher)
                completeStep.tag(OnboardingStep.complete)
            }
            .tabViewStyle(.verticalPage)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.12, blue: 0.15),
                Color(red: 0.08, green: 0.08, blue: 0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)

                Text("Welcome, Seeker")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text("The Stoics taught that wisdom must be personal. Let me understand your path, so I may guide you well.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: { withAnimation { currentStep = .name } }) {
                    Text("Begin")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Name Step

    private var nameStep: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("What shall I call you?")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                TextField("Your name", text: $userName)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)

                Text("Marcus wrote his meditations to himself. This practice will be yours.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                nextButton(to: .profession, enabled: !userName.isEmpty)
            }
            .padding()
        }
    }

    // MARK: - Profession Step

    private var professionStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("What is your work?")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                Text("Each path has its own trials.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Profession.allCases.prefix(8), id: \.self) { profession in
                        professionButton(profession)
                    }
                }

                // More options
                ForEach(Profession.allCases.dropFirst(8), id: \.self) { profession in
                    professionButton(profession)
                }

                nextButton(to: .challenge, enabled: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical)
        }
    }

    private func professionButton(_ profession: Profession) -> some View {
        Button(action: { selectedProfession = profession }) {
            HStack(spacing: 4) {
                Image(systemName: profession.icon)
                    .font(.system(size: 10))
                Text(profession.displayName.split(separator: " ").first ?? "")
                    .font(.system(size: 10))
            }
            .foregroundColor(selectedProfession == profession ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedProfession == profession ? Color.orange : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Challenge Step

    private var challengeStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("What weighs on you?")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                Text("Name the obstacle. It becomes the way.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                ForEach(StoicFocus.allCases, id: \.self) { focus in
                    focusButton(focus)
                }

                nextButton(to: .context, enabled: true)
            }
            .padding()
        }
    }

    private func focusButton(_ focus: StoicFocus) -> some View {
        Button(action: { selectedFocus = focus }) {
            HStack {
                // Since StoicFocus doesn't have an icon property in the enum, 
                // we'll use a generic one or map it. The enum in PersistenceManager didn't have icons.
                // Wait, checking PersistenceManager... it doesn't have icons.
                Image(systemName: "sparkles") 
                    .font(.system(size: 12))
                    .frame(width: 20)
                Text(focus.displayName)
                    .font(.system(size: 11))
                Spacer()
                if selectedFocus == focus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(selectedFocus == focus ? .orange : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(selectedFocus == focus ? 0.15 : 0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Context Step

    private var contextStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Life circumstances")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                Text("Select any that apply. Or skip.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                ForEach(LifeContext.allCases, id: \.self) { context in
                    contextToggle(context)
                }

                nextButton(to: .goals, enabled: true)
            }
            .padding()
        }
    }

    private func contextToggle(_ context: LifeContext) -> some View {
        Button(action: {
            if selectedContexts.contains(context) {
                selectedContexts.remove(context)
            } else {
                selectedContexts.insert(context)
            }
        }) {
            HStack {
                Image(systemName: context.icon)
                    .font(.system(size: 10))
                    .frame(width: 18)
                Text(context.displayName)
                    .font(.system(size: 10))
                Spacer()
                Image(systemName: selectedContexts.contains(context) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedContexts.contains(context) ? .orange : .gray)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Goals Step

    private var goalsStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("What virtue calls you?")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                Text("The four cardinal virtues + Stoic practices.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(StoicGoal.allCases, id: \.self) { goal in
                        goalButton(goal)
                    }
                }

                nextButton(to: .philosopher, enabled: !selectedGoals.isEmpty)
            }
            .padding()
        }
    }

    private func goalButton(_ goal: StoicGoal) -> some View {
        Button(action: {
            if selectedGoals.contains(goal) {
                selectedGoals.remove(goal)
            } else {
                selectedGoals.insert(goal)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: goal.icon)
                    .font(.system(size: 16))
                Text(goal.rawValue.capitalized)
                    .font(.system(size: 10))
            }
            .foregroundColor(selectedGoals.contains(goal) ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedGoals.contains(goal) ? Color.orange : Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Philosopher Step

    private var philosopherStep: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Choose your guide")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                ForEach(PreferredPhilosopher.allCases, id: \.self) { philosopher in
                    philosopherButton(philosopher)
                }

                nextButton(to: .complete, enabled: true)
            }
            .padding()
        }
    }

    private func philosopherButton(_ philosopher: PreferredPhilosopher) -> some View {
        Button(action: { selectedPhilosopher = philosopher }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(philosopher.displayName)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    if selectedPhilosopher == philosopher {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                Text(philosopher.description)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .foregroundColor(selectedPhilosopher == philosopher ? .orange : .white)
            .padding(10)
            .background(Color.white.opacity(selectedPhilosopher == philosopher ? 0.15 : 0.05))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Complete Step

    private var completeStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)

                Text("Your path is set")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text("I will tailor the wisdom of the Stoics to your journey as \(selectedProfession.displayName) working on \(selectedFocus.displayName).")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button(action: completeOnboarding) {
                    Text("Begin Practice")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }

    // MARK: - Navigation

    private func nextButton(to step: OnboardingStep, enabled: Bool) -> some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            withAnimation { currentStep = step }
        }) {
            HStack {
                Text("Continue")
                Image(systemName: "chevron.down")
            }
            .font(.system(size: 12))
            .foregroundColor(enabled ? .orange : .gray)
            .padding(.top, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }

    private func completeOnboarding() {
        WKInterfaceDevice.current().play(.success)

        // Save profile
        profileManager.profile = UserProfile(
            name: userName.isEmpty ? "Friend" : userName,
            profession: selectedProfession,
            currentFocus: selectedFocus,
            lifeContext: Array(selectedContexts),
            stoicGoals: Array(selectedGoals),
            preferredPhilosopher: selectedPhilosopher,
            onboardingCompleted: true
        )
        
        isPresented = false
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep {
    case welcome
    case name
    case profession
    case challenge
    case context
    case goals
    case philosopher
    case complete
}
