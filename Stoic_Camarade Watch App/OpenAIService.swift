//
//  OpenAIService.swift
//  StoicCamarade
//
//  OpenAI-compatible service (works with OpenAI and OpenRouter)
//

import Foundation

class OpenAIService: LLMServiceBase {
    private let apiKey: String
    private let model: LLMModel
    private let baseURL: String

    /// Fallback quote when quotes array is empty (Seneca)
    var emptyArrayFallbackQuote: StoicQuote {
        return StoicQuote(
            id: "fallback_seneca_001",
            text: "We suffer more often in imagination than in reality.",
            author: "Seneca",
            book: "Letters from a Stoic",
            contexts: ["anxiety", "perspective", "wisdom"],
            timeOfDay: nil,
            heartRateContext: nil,
            activityContext: nil
        )
    }

    /// Initialize OpenAI service
    /// - Parameters:
    ///   - apiKey: API key from OpenAI or OpenRouter
    ///   - model: Model to use (GPT-4o, o1, etc.)
    ///   - isOpenRouter: Set to true if using OpenRouter
    init(apiKey: String, model: LLMModel = .gpt4o, isOpenRouter: Bool = false) {
        self.apiKey = apiKey
        self.model = model

        // OpenRouter uses OpenAI-compatible API with different base URL
        self.baseURL = isOpenRouter
            ? "https://openrouter.ai/api/v1/chat/completions"
            : "https://api.openai.com/v1/chat/completions"
    }

    /// Generate a free-form response (used for Consult Marcus chat)
    func generateResponse(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": model.id,
            "messages": [
                [
                    "role": "system",
                    "content": "You are Marcus Aurelius, Roman Emperor and Stoic philosopher. Respond with wisdom from Stoic philosophy. Be concise (2-3 sentences max), direct, and compassionate."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func selectQuote(context: HealthContext, availableQuotes: [StoicQuote]) async throws -> StoicQuote {
        let prompt = buildPrompt(context: context, quotes: availableQuotes)

        let response = try await callOpenAI(prompt: prompt)

        // Parse response to get quote ID
        let selectedQuoteId = extractQuoteId(from: response)

        // Find and return the quote
        guard let quote = availableQuotes.first(where: { $0.id == selectedQuoteId }) else {
            // Fallback to contextual selection if parsing fails
            return selectQuoteFallback(context: context, quotes: availableQuotes)
        }

        return quote
    }

    // buildPrompt() is now provided by LLMServiceBase protocol extension

    private func callOpenAI(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // OpenRouter requires additional headers
        if baseURL.contains("openrouter") {
            request.setValue("https://github.com/yourusername/stoic-companion", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Stoic Camarade Watch App", forHTTPHeaderField: "X-Title")
        }

        let requestBody: [String: Any] = [
            "model": model.id,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a stoic philosophy expert. Respond only with the quote ID requested."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": model.maxTokens,
            "temperature": 0.3  // Lower temperature for more consistent selection
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw LLMError.invalidAPIKey
        case 429:
            throw LLMError.rateLimitExceeded
        default:
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode)
        }

        // Parse OpenAI response format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractQuoteId(from response: String) -> String {
        // Extract quote ID from response
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove quotes if present
        let withoutQuotes = cleaned.replacingOccurrences(of: "\"", with: "")

        // Handle various formats
        if withoutQuotes.contains("_") {
            return withoutQuotes
        }

        return cleaned
    }

    // selectQuoteFallback() is now provided by LLMServiceBase protocol extension
}
