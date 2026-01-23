//
//  LLMService.swift
//  StoicCamarade
//
//  Protocol for LLM providers (Claude, OpenAI, Gemini, OpenRouter)
//

import Foundation

// MARK: - LLM Service Protocol

/// Protocol that all LLM providers must implement
protocol LLMService {
    /// Selects the most appropriate stoic quote based on health context
    /// - Parameters:
    ///   - context: Current health and temporal context
    ///   - availableQuotes: Array of quotes to choose from
    /// - Returns: The selected quote
    func selectQuote(context: HealthContext, availableQuotes: [StoicQuote]) async throws -> StoicQuote

    /// Generates a free-form response for chat and AI features
    /// - Parameter prompt: The prompt to respond to
    /// - Returns: The AI-generated response
    func generateResponse(prompt: String) async throws -> String
}

// MARK: - Provider Types

enum LLMProvider: String, CaseIterable {
    case claude = "Claude (Anthropic)"
    case openai = "OpenAI GPT"
    case openrouter = "OpenRouter (Multi-Model)"
    case gemini = "Google Gemini"

    var displayName: String {
        return self.rawValue
    }

    /// Returns true if this provider uses OpenAI-compatible API
    var isOpenAICompatible: Bool {
        return self == .openai || self == .openrouter
    }
}

// MARK: - Model Configurations

struct LLMModel {
    let id: String
    let displayName: String
    let provider: LLMProvider
    let maxTokens: Int

    // MARK: - Claude Models
    static let claudeSonnet4_5 = LLMModel(
        id: "claude-sonnet-4-5-20250929",
        displayName: "Claude Sonnet 4.5 (Recommended)",
        provider: .claude,
        maxTokens: 50
    )

    static let claudeOpus4_5 = LLMModel(
        id: "claude-opus-4-5-20251101",
        displayName: "Claude Opus 4.5 (Most Capable)",
        provider: .claude,
        maxTokens: 50
    )

    static let claudeHaiku4_5 = LLMModel(
        id: "claude-haiku-4-5-20250929",
        displayName: "Claude Haiku 4.5 (Fastest)",
        provider: .claude,
        maxTokens: 50
    )

    // MARK: - OpenAI Models
    static let gpt4o = LLMModel(
        id: "gpt-4o",
        displayName: "GPT-4o (Latest)",
        provider: .openai,
        maxTokens: 50
    )

    static let gpt4oMini = LLMModel(
        id: "gpt-4o-mini",
        displayName: "GPT-4o Mini (Cost-Effective)",
        provider: .openai,
        maxTokens: 50
    )

    static let o1 = LLMModel(
        id: "o1",
        displayName: "o1 (Reasoning)",
        provider: .openai,
        maxTokens: 50
    )

    static let o1Mini = LLMModel(
        id: "o1-mini",
        displayName: "o1 Mini (Fast Reasoning)",
        provider: .openai,
        maxTokens: 50
    )

    // MARK: - Gemini Models
    static let gemini2Flash = LLMModel(
        id: "gemini-2.0-flash-exp",
        displayName: "Gemini 2.0 Flash (Fast)",
        provider: .gemini,
        maxTokens: 50
    )

    static let gemini2Pro = LLMModel(
        id: "gemini-2.0-pro-exp",
        displayName: "Gemini 2.0 Pro (Capable)",
        provider: .gemini,
        maxTokens: 50
    )

    static let gemini1_5Pro = LLMModel(
        id: "gemini-1.5-pro",
        displayName: "Gemini 1.5 Pro",
        provider: .gemini,
        maxTokens: 50
    )

    // MARK: - Gemini 2.5 & 3.0 Models (Advanced)
    static let gemini25Flash = LLMModel(
        id: "gemini-2.5-flash",
        displayName: "Gemini 2.5 Flash (Efficient)",
        provider: .gemini,
        maxTokens: 100
    )

    static let gemini3Pro = LLMModel(
        id: "gemini-3-pro-preview",
        displayName: "Gemini 3 Pro (Best Reasoning)",
        provider: .gemini,
        maxTokens: 200
    )

    // MARK: - Nano Banana Image Models
    static let nanoBanana = LLMModel(
        id: "gemini-2.5-flash-image",
        displayName: "Nano Banana (Fast Image Gen)",
        provider: .gemini,
        maxTokens: 0  // Images, not tokens
    )

    static let nanoBananaPro = LLMModel(
        id: "gemini-3-pro-image-preview",
        displayName: "Nano Banana Pro (Quality Image Gen)",
        provider: .gemini,
        maxTokens: 0  // Images, not tokens
    )

    // Alternative image model (confirmed working)
    static let geminiImageGen = LLMModel(
        id: "gemini-2.0-flash-exp-image-generation",
        displayName: "Gemini 2.0 Image Gen (Stable)",
        provider: .gemini,
        maxTokens: 0
    )

    // MARK: - OpenRouter Models (uses OpenAI-compatible names)
    static let openrouterClaude = LLMModel(
        id: "anthropic/claude-sonnet-4-5",
        displayName: "Claude Sonnet 4.5 (via OpenRouter)",
        provider: .openrouter,
        maxTokens: 50
    )

    static let openrouterGPT4o = LLMModel(
        id: "openai/gpt-4o",
        displayName: "GPT-4o (via OpenRouter)",
        provider: .openrouter,
        maxTokens: 50
    )

    static let openrouterGemini2 = LLMModel(
        id: "google/gemini-2.0-flash-exp:free",
        displayName: "Gemini 2.0 Flash (via OpenRouter, Free)",
        provider: .openrouter,
        maxTokens: 50
    )

    // MARK: - Recommended Models by Use Case
    static let recommended = claudeSonnet4_5
    static let fastestAndCheap = claudeHaiku4_5
    static let mostCapable = claudeOpus4_5
    static let free = openrouterGemini2

    // MARK: - Gemini Recommended by Use Case
    static let geminiRecommended = gemini25Flash      // Best balance for watchOS
    static let geminiReasoning = gemini3Pro          // Deep philosophical discussions
    static let geminiImageFast = nanoBanana          // Quick background generation
    static let geminiImageQuality = nanoBananaPro   // High-quality quote cards
}

// MARK: - Common Errors

enum LLMError: Error, LocalizedError {
    case requestFailed(statusCode: Int)
    case invalidResponse
    case invalidAPIKey
    case invalidURL(String)
    case rateLimitExceeded
    case networkError(Error)
    case modelNotAvailable
    case emptyQuoteArray

    var errorDescription: String? {
        switch self {
        case .requestFailed(let code):
            return "LLM request failed with status code \(code)"
        case .invalidResponse:
            return "Invalid response from LLM provider"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .modelNotAvailable:
            return "Selected model is not available"
        case .emptyQuoteArray:
            return "No quotes available to select from"
        }
    }
}
// MARK: - Shared Models

struct StoicQuote: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let author: String
    let book: String?
    let contexts: [String]
    let timeOfDay: String?
    let heartRateContext: String?
    let activityContext: String?
    
    static func == (lhs: StoicQuote, rhs: StoicQuote) -> Bool {
        lhs.id == rhs.id
    }
}

enum StressLevel: String, Codable {
    case low = "low"
    case normal = "normal"
    case elevated = "elevated"
    case high = "high"
}

struct HealthContext {
    var heartRate: Double?
    var heartRateVariability: Double?
    var timeOfDay: String?
    var stressLevel: StressLevel
    var isActive: Bool
    var primaryContext: String
    var activeCalories: Double?
    var steps: Double?
}

// MARK: - Shared Implementation for LLM Services

/// Protocol providing shared implementation for quote selection and prompt building
/// Eliminates code duplication across Claude, Gemini, and OpenAI services
protocol LLMServiceBase: LLMService {
    /// The fallback quote to use when the quotes array is empty
    /// Each service can provide their own default philosopher
    var emptyArrayFallbackQuote: StoicQuote { get }
}

extension LLMServiceBase {

    /// Build standardized prompt for quote selection based on health context
    /// - Parameters:
    ///   - context: Current health and temporal context
    ///   - quotes: Available quotes to choose from
    /// - Returns: Formatted prompt for LLM
    func buildPrompt(context: HealthContext, quotes: [StoicQuote]) -> String {
        let quotesJson = quotes.map { quote in
            """
            {
                "id": "\(quote.id)",
                "text": "\(quote.text)",
                "author": "\(quote.author)",
                "contexts": \(quote.contexts)
            }
            """
        }.joined(separator: ",\n")

        return """
        You are a wise stoic companion helping someone by selecting the perfect quote for their current moment.

        Current Context:
        - Heart Rate: \(context.heartRate.map { "\(Int($0)) bpm" } ?? "unknown")
        - Time of Day: \(context.timeOfDay ?? "unknown")
        - Stress Level: \(context.stressLevel)
        - Active: \(context.isActive)
        - Primary Context: \(context.primaryContext)
        - Active Calories Today: \(context.activeCalories.map { "\(Int($0)) kcal" } ?? "unknown")
        - Steps Today: \(context.steps.map { "\(Int($0))" } ?? "unknown")

        Available Quotes:
        [\(quotesJson)]

        Based on this person's current physiological and temporal context, select the single most appropriate stoic quote that would be most helpful and meaningful right now.

        Consider:
        1. If stressed (elevated heart rate), choose quotes about control and acceptance
        2. If morning, choose quotes about intention and starting the day
        3. If evening, choose quotes about reflection and contentment
        4. If inactive, choose quotes about action and urgency
        5. If active, choose quotes about discipline and strength

        Respond ONLY with the quote ID (e.g., "ma_001" or "ep_003" or "se_005"). Nothing else.
        """
    }

    /// Fallback quote selection when LLM API fails
    /// Uses contextual filtering to match quotes to current situation
    /// - Parameters:
    ///   - context: Current health and temporal context
    ///   - quotes: Available quotes to choose from
    /// - Returns: Best matching quote or fallback if array is empty
    func selectQuoteFallback(context: HealthContext, quotes: [StoicQuote]) -> StoicQuote {
        // Guard against empty quote array
        guard !quotes.isEmpty else {
            return emptyArrayFallbackQuote
        }

        // Fallback logic if LLM API fails
        let filtered = quotes.filter { quote in
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

        // Return random from filtered, or random from all (safe now since we checked isEmpty)
        return filtered.randomElement() ?? quotes.randomElement()!
    }
}
