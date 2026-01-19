//
//  StoicIntents.swift
//  StoicCompanion
//
//  Siri integration using App Intents framework
//

import Foundation
import AppIntents
import SwiftUI

// MARK: - Main Intent

struct GetStoicWisdomIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Stoic Wisdom"
    static var description = IntentDescription("Receive a stoic quote tailored to your current state")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let healthManager = HealthDataManager()
        await healthManager.requestAuthorization()
        
        let context = await healthManager.getCurrentContext()
        let quoteManager = QuoteManager()
        let quote = await quoteManager.getContextualQuote(
            context: context,
            profile: ProfileManager.shared.profile,
            dynamicContext: DynamicUserContextManager.shared.dynamicContext
        )
        
        let dialog = IntentDialog(stringLiteral: """
        \(quote.text)
        
        — \(quote.author), \(quote.book ?? "Meditations")
        """)
        
        return .result(
            dialog: dialog,
            view: StoicQuoteView(quote: quote, context: context)
        )
    }
}

// MARK: - Additional Intents

struct MorningStoicIntent: AppIntent {
    static var title: LocalizedStringResource = "Morning Stoic Wisdom"
    static var description = IntentDescription("Start your day with stoic intention")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager()
        var context = await healthManager.getCurrentContext()
        context.primaryContext = "morning"
        
        let quoteManager = QuoteManager()
        let quote = await quoteManager.getContextualQuote(
            context: context,
            profile: ProfileManager.shared.profile,
            dynamicContext: DynamicUserContextManager.shared.dynamicContext
        )
        
        return .result(dialog: IntentDialog(stringLiteral: """
        Good morning. \(quote.text)
        
        — \(quote.author)
        """))
    }
}

struct EveningStoicIntent: AppIntent {
    static var title: LocalizedStringResource = "Evening Stoic Reflection"
    static var description = IntentDescription("End your day with stoic reflection")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager()
        var context = await healthManager.getCurrentContext()
        context.primaryContext = "evening"
        
        let quoteManager = QuoteManager()
        let quote = await quoteManager.getContextualQuote(
            context: context,
            profile: ProfileManager.shared.profile,
            dynamicContext: DynamicUserContextManager.shared.dynamicContext
        )
        
        return .result(dialog: IntentDialog(stringLiteral: """
        As you reflect on your day: \(quote.text)
        
        — \(quote.author)
        """))
    }
}

struct StressReliefIntent: AppIntent {
    static var title: LocalizedStringResource = "Stoic Calm"
    static var description = IntentDescription("Find calm in challenging moments")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager()
        var context = await healthManager.getCurrentContext()
        context.primaryContext = "stress"
        context.stressLevel = .elevated
        
        let quoteManager = QuoteManager()
        let quote = await quoteManager.getContextualQuote(
            context: context,
            profile: ProfileManager.shared.profile,
            dynamicContext: DynamicUserContextManager.shared.dynamicContext
        )
        
        return .result(dialog: IntentDialog(stringLiteral: """
        Take a breath. \(quote.text)
        
        — \(quote.author)
        """))
    }
}

// MARK: - Snippet View

struct StoicQuoteView: View {
    let quote: StoicQuote
    let context: HealthContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote
            Text(quote.text)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(.primary)
            
            // Attribution
            HStack {
                Text("—")
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.author)
                        .font(.system(size: 12, weight: .semibold))
                    Text(quote.book ?? "Meditations")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.orange)
            
            Divider()
            
            // Context
            HStack(spacing: 16) {
                if let hr = context.heartRate {
                    Label("\(Int(hr))", systemImage: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                
                if let steps = context.steps {
                    Label("\(steps)", systemImage: "figure.walk")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
}

// MARK: - App Shortcuts Provider

struct StoicShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetStoicWisdomIntent(),
            phrases: [
                "Get stoic wisdom in \(.applicationName)",
                "Get \(.applicationName) wisdom",
                "Give me stoic advice in \(.applicationName)",
                "\(.applicationName) stoic quote"
            ],
            shortTitle: "Stoic Wisdom",
            systemImageName: "laurel.leading"
        )
        
        AppShortcut(
            intent: MorningStoicIntent(),
            phrases: [
                "Good morning \(.applicationName)",
                "Start my day with \(.applicationName)",
                "Morning stoic wisdom in \(.applicationName)"
            ],
            shortTitle: "Morning Wisdom",
            systemImageName: "sunrise.fill"
        )
        
        AppShortcut(
            intent: EveningStoicIntent(),
            phrases: [
                "Evening \(.applicationName)",
                "End my day with \(.applicationName)",
                "Evening stoic reflection in \(.applicationName)"
            ],
            shortTitle: "Evening Reflection",
            systemImageName: "moon.fill"
        )
        
        AppShortcut(
            intent: StressReliefIntent(),
            phrases: [
                "I need calm in \(.applicationName)",
                "Help me find calm in \(.applicationName)",
                "Stoic stress relief in \(.applicationName)",
                "I'm stressed in \(.applicationName)"
            ],
            shortTitle: "Find Calm",
            systemImageName: "heart.circle.fill"
        )
    }
}

