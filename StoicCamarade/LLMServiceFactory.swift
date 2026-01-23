//
//  LLMServiceFactory.swift
//  StoicCompanion
//
//  Factory for creating LLM service instances based on provider selection
//

import Foundation

class LLMServiceFactory {

    /// Creates an LLM service based on configuration
    /// - Returns: Configured LLM service instance
    static func createService() -> LLMService {
        let provider = Config.llmProvider
        let model = Config.llmModel

        switch provider {
        case .claude:
            return ClaudeService(
                apiKey: Config.claudeAPIKey,
                model: model
            )

        case .openai:
            return OpenAIService(
                apiKey: Config.openAIKey,
                model: model,
                isOpenRouter: false
            )

        case .openrouter:
            return OpenAIService(
                apiKey: Config.openRouterKey,
                model: model,
                isOpenRouter: true
            )

        case .gemini:
            return GeminiService(
                apiKey: Config.geminiKey,
                model: model
            )
        }
    }

    /// Creates a specific provider service (for testing or advanced usage)
    /// - Parameters:
    ///   - provider: The LLM provider to use
    ///   - apiKey: API key for the provider
    ///   - model: Model to use (optional, uses default if not specified)
    /// - Returns: Configured LLM service instance
    static func createService(
        provider: LLMProvider,
        apiKey: String,
        model: LLMModel? = nil
    ) -> LLMService {
        let selectedModel = model ?? defaultModel(for: provider)

        switch provider {
        case .claude:
            return ClaudeService(apiKey: apiKey, model: selectedModel)

        case .openai:
            return OpenAIService(apiKey: apiKey, model: selectedModel, isOpenRouter: false)

        case .openrouter:
            return OpenAIService(apiKey: apiKey, model: selectedModel, isOpenRouter: true)

        case .gemini:
            return GeminiService(apiKey: apiKey, model: selectedModel)
        }
    }

    /// Returns the default model for a given provider
    /// - Parameter provider: The LLM provider
    /// - Returns: Default model for that provider
    private static func defaultModel(for provider: LLMProvider) -> LLMModel {
        switch provider {
        case .claude:
            return .claudeSonnet4_5
        case .openai:
            return .gpt4o
        case .openrouter:
            return .openrouterGemini2  // Free option by default
        case .gemini:
            return .gemini2Flash
        }
    }

    /// Lists all available models for a given provider
    /// - Parameter provider: The LLM provider
    /// - Returns: Array of available models
    static func availableModels(for provider: LLMProvider) -> [LLMModel] {
        switch provider {
        case .claude:
            return [
                .claudeSonnet4_5,
                .claudeOpus4_5,
                .claudeHaiku4_5
            ]

        case .openai:
            return [
                .gpt4o,
                .gpt4oMini,
                .o1,
                .o1Mini
            ]

        case .openrouter:
            return [
                .openrouterGemini2,  // Free
                .openrouterClaude,
                .openrouterGPT4o
            ]

        case .gemini:
            return [
                .gemini2Flash,
                .gemini2Pro,
                .gemini1_5Pro
            ]
        }
    }

    /// Validates that the required API key is configured for a provider
    /// - Parameter provider: The LLM provider to validate
    /// - Returns: true if API key is configured, false otherwise
    static func isConfigured(provider: LLMProvider) -> Bool {
        switch provider {
        case .claude:
            return !Config.claudeAPIKey.isEmpty && Config.claudeAPIKey != "YOUR_CLAUDE_API_KEY_HERE"

        case .openai:
            return !Config.openAIKey.isEmpty && Config.openAIKey != "YOUR_OPENAI_API_KEY_HERE"

        case .openrouter:
            return !Config.openRouterKey.isEmpty && Config.openRouterKey != "YOUR_OPENROUTER_API_KEY_HERE"

        case .gemini:
            return !Config.geminiKey.isEmpty && Config.geminiKey != "YOUR_GEMINI_API_KEY_HERE"
        }
    }

    /// Returns a user-friendly error message for unconfigured providers
    /// - Parameter provider: The LLM provider
    /// - Returns: Setup instructions
    static func setupInstructions(for provider: LLMProvider) -> String {
        switch provider {
        case .claude:
            return """
            ⚠️ Claude API key not configured!

            Get your API key at: https://console.anthropic.com/
            Add it to Config.swift as: claudeAPIKey = "sk-ant-..."
            """

        case .openai:
            return """
            ⚠️ OpenAI API key not configured!

            Get your API key at: https://platform.openai.com/
            Add it to Config.swift as: openAIKey = "sk-..."
            """

        case .openrouter:
            return """
            ⚠️ OpenRouter API key not configured!

            Get your API key at: https://openrouter.ai/
            Add it to Config.swift as: openRouterKey = "sk-or-..."

            💡 OpenRouter gives access to 100+ models through one API!
            """

        case .gemini:
            return """
            ⚠️ Gemini API key not configured!

            Get your API key at: https://aistudio.google.com/
            Add it to Config.swift as: geminiKey = "..."
            """
        }
    }
}
