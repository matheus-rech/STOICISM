//
//  Config.swift
//  StoicCamarade
//
//  Configuration file for API keys, app settings, and RAG Service
//
//

import Foundation

// MARK: - Configuration

struct Config {
    // MARK: - LLM Provider Selection

    /// Choose your LLM provider: .claude, .openai, .openrouter, or .gemini
    /// Currently set to Gemini for best experience
    static let llmProvider: LLMProvider = .gemini

    /// Choose your model (must match provider)
    static let llmModel: LLMModel = .gemini25Flash

    // MARK: - API Keys
    // ⚠️ SECURITY: API keys should be provided via environment variables or Secrets.plist
    // See Config.xcconfig.template for setup instructions
    // Never hardcode API keys in source code!

    static let claudeAPIKey = ""  // Load from environment or Secrets.plist
    static let openAIKey = ""     // Load from environment or Secrets.plist
    static let openRouterKey = "" // Load from environment or Secrets.plist
    static let geminiKey = ""     // Load from environment or Secrets.plist

    // MARK: - RAG API Settings

    static let ragAPIEndpoint = "https://stoicism-production.up.railway.app"
    static let useRAGAPI = true
    static let ragFallbackToLLM = true

    // MARK: - App Settings

    static let healthDataRefreshInterval: TimeInterval = 60
    static let debugMode = true
    static let useLLMAPI = true
    static let minimumQuoteInterval: TimeInterval = 10
}

// MARK: - Config Extensions

extension Config {
    static func loadAPIKeyFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ClaudeAPIKey"] as? String else {
            return nil
        }
        return key
    }
}

extension Config {
    private static func loadAPIKey(
        envVar: String,
        plistKey: String,
        hardcodedValue: String,
        providerName: String,
        signupURL: String
    ) -> String {
        if let envKey = ProcessInfo.processInfo.environment[envVar], !envKey.isEmpty {
            return envKey
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let plistValue = dict[plistKey] as? String,
           !plistValue.isEmpty {
            return plistValue
        }
        if !hardcodedValue.isEmpty && !hardcodedValue.hasPrefix("YOUR_") {
            return hardcodedValue
        }
        if !useLLMAPI { return "" }
        if providerName.lowercased() == llmProvider.rawValue.lowercased().split(separator: " ").first?.lowercased() {
             print("⚠️ \(providerName) API key not configured!")
        }
        return ""
    }

    static var currentAPIKey: String {
        switch llmProvider {
        case .claude:
            return loadAPIKey(envVar: "CLAUDE_API_KEY", plistKey: "ClaudeAPIKey", hardcodedValue: claudeAPIKey, providerName: "Claude", signupURL: "https://console.anthropic.com/")
        case .openai:
            return loadAPIKey(envVar: "OPENAI_API_KEY", plistKey: "OpenAIKey", hardcodedValue: openAIKey, providerName: "OpenAI", signupURL: "https://platform.openai.com/")
        case .openrouter:
            return loadAPIKey(envVar: "OPENROUTER_API_KEY", plistKey: "OpenRouterKey", hardcodedValue: openRouterKey, providerName: "OpenRouter", signupURL: "https://openrouter.ai/")
        case .gemini:
            return loadAPIKey(envVar: "GEMINI_API_KEY", plistKey: "GeminiKey", hardcodedValue: geminiKey, providerName: "Gemini", signupURL: "https://aistudio.google.com/")
        }
    }
}

// MARK: - RAG Service

/// Service that retrieves contextually-relevant Stoic quotes via semantic search
class RAGService {

    // MARK: - API Configuration

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = Config.ragAPIEndpoint) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Request/Response Models

    struct QuoteRequest: Encodable {
        let context: ContextPayload
        let query: String?

        struct ContextPayload: Encodable {
            let stress_level: String
            let time_of_day: String
            let is_active: Bool
            let heart_rate: Double?
            let hrv: Double?
        }
    }

    struct QuoteResponse: Decodable {
        let quote: QuoteData
        let similarity_score: Double?
        let philosopher: String?

        struct QuoteData: Decodable {
            let id: String?
            let text: String
            let author: String
            let source: String?
            let book: String?
            let contexts: [String]?
        }
    }

    struct HealthResponse: Decodable {
        let status: String
        let version: String
    }

    // MARK: - Methods

    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return false }
            let health = try JSONDecoder().decode(HealthResponse.self, from: data)
            return health.status == "healthy"
        } catch {
            if Config.debugMode { print("🔴 RAG health check failed: \(error.localizedDescription)") }
            return false
        }
    }

    func getContextualQuote(context: HealthContext, query: String? = nil) async throws -> StoicQuote {
        guard let url = URL(string: "\(baseURL)/quote") else { throw RAGError.invalidURL }

        let requestBody = QuoteRequest(
            context: QuoteRequest.ContextPayload(
                stress_level: context.stressLevel.rawValue,
                time_of_day: context.timeOfDay ?? "any",
                is_active: context.isActive,
                heart_rate: context.heartRate,
                hrv: context.heartRateVariability
            ),
            query: query ?? buildSemanticQuery(from: context)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        if Config.debugMode { print("🔵 RAG Request: \(context.stressLevel.rawValue)") }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw RAGError.invalidResponse }
        guard httpResponse.statusCode == 200 else { throw RAGError.requestFailed(statusCode: httpResponse.statusCode) }

        let quoteResponse = try JSONDecoder().decode(QuoteResponse.self, from: data)
        if Config.debugMode { print("🟢 RAG Response: \(quoteResponse.quote.author)") }

        return StoicQuote(
            id: quoteResponse.quote.id ?? UUID().uuidString,
            text: quoteResponse.quote.text,
            author: quoteResponse.quote.author,
            book: quoteResponse.quote.book ?? quoteResponse.quote.source,
            contexts: quoteResponse.quote.contexts ?? [],
            timeOfDay: context.timeOfDay,
            heartRateContext: context.stressLevel == .elevated || context.stressLevel == .high ? "elevated" : "resting",
            activityContext: context.isActive ? "active" : "resting"
        )
    }

    private func buildSemanticQuery(from context: HealthContext) -> String {
        var queryParts: [String] = []
        switch context.stressLevel {
        case .high: queryParts.append("feeling overwhelmed and anxious")
        case .elevated: queryParts.append("dealing with stress")
        case .normal: queryParts.append("seeking wisdom")
        case .low: queryParts.append("feeling calm and reflective")
        }
        if let timeOfDay = context.timeOfDay {
            switch timeOfDay {
            case "morning": queryParts.append("starting the day with purpose")
            case "afternoon": queryParts.append("maintaining focus")
            case "evening": queryParts.append("reflecting on the day")
            case "night": queryParts.append("finding peace before rest")
            default: break
            }
        }
        if context.isActive { queryParts.append("during physical activity") }
        return queryParts.joined(separator: ", ")
    }
}

// MARK: - RAG Errors

enum RAGError: Error, LocalizedError {
    case invalidURL, invalidResponse, apiUnavailable
    case requestFailed(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid RAG API URL"
        case .invalidResponse: return "Invalid response from RAG API"
        case .requestFailed(let code): return "RAG request failed with status code \(code)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiUnavailable: return "RAG API is currently unavailable"
        }
    }
}

// MARK: - LLMService Conformance

extension RAGService: LLMService {
    func selectQuote(context: HealthContext, availableQuotes: [StoicQuote]) async throws -> StoicQuote {
        return try await getContextualQuote(context: context)
    }

    func generateResponse(prompt: String) async throws -> String {
        throw RAGError.apiUnavailable
    }
}
