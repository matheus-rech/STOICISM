//
//  LLMService.swift
//  StoicCompanion
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
}

// MARK: - Common Errors

enum LLMError: Error, LocalizedError {
    case requestFailed(statusCode: Int)
    case invalidResponse
    case invalidAPIKey
    case rateLimitExceeded
    case networkError(Error)
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .requestFailed(let code):
            return "LLM request failed with status code \(code)"
        case .invalidResponse:
            return "Invalid response from LLM provider"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .modelNotAvailable:
            return "Selected model is not available"
        }
    }
}
