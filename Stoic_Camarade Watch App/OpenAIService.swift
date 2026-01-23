//
//  OpenAIService.swift
//  StoicCamarade
//
//  OpenAI-compatible service (works with OpenAI and OpenRouter)
//

import Foundation

class OpenAIService: LLMService {
    private let apiKey: String
    private let model: LLMModel
    private let baseURL: String

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

    private func buildPrompt(context: HealthContext, quotes: [StoicQuote]) -> String {
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

    private func selectQuoteFallback(context: HealthContext, quotes: [StoicQuote]) -> StoicQuote {
        // Guard against empty quote array
        guard !quotes.isEmpty else {
            // Return a hardcoded fallback quote if array is empty
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

        // Fallback logic if API fails
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
