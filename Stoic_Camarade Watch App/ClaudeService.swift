//
//  ClaudeService.swift
//  StoicCamarade
//
//  Handles communication with Claude API for intelligent quote selection
//

import Foundation

class ClaudeService: LLMServiceBase {
    private let apiKey: String
    private let model: LLMModel
    private let apiURL = "https://api.anthropic.com/v1/messages"

    /// Fallback quote when quotes array is empty (Marcus Aurelius)
    var emptyArrayFallbackQuote: StoicQuote {
        return StoicQuote(
            id: "fallback_marcus_001",
            text: "The impediment to action advances action. What stands in the way becomes the way.",
            author: "Marcus Aurelius",
            book: "Meditations",
            contexts: ["obstacle", "action", "adversity"],
            timeOfDay: nil,
            heartRateContext: nil,
            activityContext: nil
        )
    }

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

    func generateResponse(prompt: String) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw LLMError.invalidURL(apiURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": model.id,
            "max_tokens": 200,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // buildPrompt() is now provided by LLMServiceBase protocol extension
    
    private func callClaude(prompt: String) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw LLMError.invalidURL(apiURL)
        }
        var request = URLRequest(url: url)
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw LLMError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
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
    
    // selectQuoteFallback() is now provided by LLMServiceBase protocol extension
}

// ClaudeError is now replaced by LLMError in LLMService.swift
