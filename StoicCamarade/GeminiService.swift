//
//  GeminiService.swift
//  StoicCompanion
//
//  Google Gemini AI service integration
//

import Foundation

class GeminiService: LLMService {
    private let apiKey: String
    private let model: LLMModel
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    /// Initialize Gemini service
    /// - Parameters:
    ///   - apiKey: API key from Google AI Studio
    ///   - model: Gemini model to use (2.0 Flash, 2.0 Pro, etc.)
    init(apiKey: String, model: LLMModel = .gemini2Flash) {
        self.apiKey = apiKey
        self.model = model
    }

    func selectQuote(context: HealthContext, availableQuotes: [StoicQuote]) async throws -> StoicQuote {
        let prompt = buildPrompt(context: context, quotes: availableQuotes)

        let response = try await callGemini(prompt: prompt)

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

    private func callGemini(prompt: String) async throws -> String {
        // Gemini API URL format: /models/{model}:generateContent
        let urlString = "\(baseURL)/models/\(model.id):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Gemini request format
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": model.maxTokens,
                "topP": 0.8,
                "topK": 10
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                ]
            ]
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
        case 400:
            // Check if it's an API key issue
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                if message.contains("API_KEY") || message.contains("invalid") {
                    throw LLMError.invalidAPIKey
                }
            }
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode)
        case 429:
            throw LLMError.rateLimitExceeded
        default:
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode)
        }

        // Parse Gemini response format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {

            // Check for error in response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("Gemini API Error: \(message)")
            }

            throw LLMError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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

        // Return random from filtered, or random from all if no matches
        return filtered.randomElement() ?? quotes.randomElement() ?? quotes[0]
    }
}
