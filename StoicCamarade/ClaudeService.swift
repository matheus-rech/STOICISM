//
//  ClaudeService.swift
//  StoicCompanion
//
//  Handles communication with Claude API for intelligent quote selection
//

import Foundation

class ClaudeService: LLMService {
    private let apiKey: String
    private let model: LLMModel
    private let apiURL = "https://api.anthropic.com/v1/messages"

    /// Initialize Claude service
    /// - Parameters:
    ///   - apiKey: API key from console.anthropic.com
    ///   - model: Claude model to use (Sonnet, Opus, Haiku)
    init(apiKey: String, model: LLMModel = .claudeSonnet4_5) {
        self.apiKey = apiKey
        self.model = model
    }
    
    func selectQuote(context: HealthContext, availableQuotes: [StoicQuote]) async throws -> StoicQuote {
        let prompt = buildPrompt(context: context, quotes: availableQuotes)
        
        let response = try await callClaude(prompt: prompt)
        
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
    
    private func callClaude(prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": model.id,
            "max_tokens": model.maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractQuoteId(from response: String) -> String {
        // Extract quote ID from Claude's response
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle various formats Claude might return
        if cleaned.contains("_") {
            // Already in correct format like "ma_001"
            return cleaned
        }
        
        return cleaned
    }
    
    private func selectQuoteFallback(context: HealthContext, quotes: [StoicQuote]) -> StoicQuote {
        // Fallback logic if Claude API fails
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

// ClaudeError is now replaced by LLMError in LLMService.swift
