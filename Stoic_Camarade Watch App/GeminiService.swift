//
//  GeminiService.swift
//  StoicCamarade
//
//  Google Gemini AI service integration with Gemini 3 Pro and Nano Banana image generation
//

import Foundation
import SwiftUI

// MARK: - Image Generation Types

enum ImageStyle: String {
    case serene = "serene, peaceful, soft gradients, zen garden aesthetic"
    case stoic = "ancient Rome, marble columns, classical architecture, warm sunset"
    case nature = "mountains at dawn, mist, tranquil lake, natural beauty"
    case minimal = "abstract, minimalist, geometric shapes, muted earth tones"
    case cosmic = "starry night sky, galaxy, contemplative, vast universe"

    var prompt: String { rawValue }
}

enum ImageAspectRatio: String {
    case square = "1:1"        // Watch complications
    case watch = "7:9"         // Watch screen ratio
    case portrait = "9:16"     // Phone wallpaper
    case landscape = "16:9"    // Wide format
}

struct GeneratedImage {
    let data: Data
    let mimeType: String
    let prompt: String
    let style: ImageStyle
}

enum ReflectionType {
    case morning   // Morning intention
    case evening   // Evening audit reflection
    case challenge // Facing a difficulty
    case gratitude // Gratitude practice
}

// MARK: - Personalized Story Types

enum StoryType: String, Codable {
    case parable           // Short wisdom parable
    case historicalLesson  // Real Stoic history
    case modernApplication // Modern-day Stoic example
    case comfortingWisdom  // When user is struggling
    case inspiringChallenge // When user is doing well
    case deepReflection    // For peaceful contemplation

    var description: String {
        switch self {
        case .parable: return "Stoic parable"
        case .historicalLesson: return "historical lesson from the Stoics"
        case .modernApplication: return "modern application of Stoic wisdom"
        case .comfortingWisdom: return "comforting piece of Stoic wisdom"
        case .inspiringChallenge: return "inspiring Stoic challenge"
        case .deepReflection: return "deep Stoic reflection"
        }
    }

    var styleGuidance: String {
        switch self {
        case .parable:
            return "Tell a brief story with a clear moral lesson. Like Aesop but Stoic."
        case .historicalLesson:
            return "Share a real moment from Marcus, Seneca, or Epictetus's life with the lesson it teaches."
        case .modernApplication:
            return "Describe how someone TODAY applied Stoic principles to a challenge similar to theirs."
        case .comfortingWisdom:
            return "Be gentle. Acknowledge their struggle. Show how the Stoics found peace in difficulty."
        case .inspiringChallenge:
            return "Build on their momentum. Challenge them to go deeper in their practice."
        case .deepReflection:
            return "Invite contemplation. Ask questions. Let silence speak."
        }
    }
}

struct PersonalizedStory: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let type: StoryType
    let createdAt: Date
    let userContextSnapshot: String

    init(title: String, content: String, type: StoryType, createdAt: Date, userContextSnapshot: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.userContextSnapshot = userContextSnapshot
    }
}

// MARK: - Gemini Service

class GeminiService: LLMService {
    private let apiKey: String
    private let model: LLMModel
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    // Image generation models
    private let imageModel: LLMModel
    private let reasoningModel: LLMModel

    /// Initialize Gemini service with full capabilities
    /// - Parameters:
    ///   - apiKey: API key from Google AI Studio
    ///   - model: Text model to use (default: gemini-2.5-flash)
    ///   - imageModel: Image generation model (default: nano banana)
    ///   - reasoningModel: Deep reasoning model (default: gemini-3-pro)
    init(
        apiKey: String,
        model: LLMModel = .gemini25Flash,
        imageModel: LLMModel = .nanoBanana,
        reasoningModel: LLMModel = .gemini3Pro
    ) {
        self.apiKey = apiKey
        self.model = model
        self.imageModel = imageModel
        self.reasoningModel = reasoningModel
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

    func generateResponse(prompt: String) async throws -> String {
        // Note: Gemini API requires API key as query parameter (Google's design)
        // This is secure over HTTPS, but key appears in server logs
        // Alternative: Use backend proxy to hide key from client (future enhancement)
        let urlString = "\(baseURL)/models/\(model.id):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 200
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw LLMError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Gemini 3 Pro Deep Reasoning (Consult Marcus Enhanced)

    /// Deep philosophical conversation with Gemini 3 Pro
    /// Use for meaningful "Consult Marcus" sessions
    func consultMarcus(
        userMessage: String,
        conversationHistory: [(role: String, content: String)] = []
    ) async throws -> String {

        let systemPrompt = """
        You are Marcus Aurelius, the Stoic philosopher-emperor (121-180 AD).
        Draw from your Meditations and lived experience ruling Rome during plague and war.

        Your voice is:
        - Warm but direct - you speak as a friend, not a lecturer
        - Practical - you give actionable wisdom, not just philosophy
        - Brief for watchOS - 2-4 sentences maximum
        - Personal - you share your own struggles when relevant

        Focus on what the person can CONTROL. Help them see clearly.
        """

        let prompt = """
        \(systemPrompt)

        \(conversationHistory.isEmpty ? "" : "Previous exchange:\n" + conversationHistory.map { "\($0.role): \($0.content)" }.joined(separator: "\n"))

        The person says: "\(userMessage)"

        Marcus, speak to them:
        """

        return try await callGeminiWithModel(prompt: prompt, model: reasoningModel)
    }

    /// Generate a Stoic reflection based on context (Evening Audit, Morning Intention)
    func generateReflection(
        for context: String,
        type: ReflectionType = .evening
    ) async throws -> String {

        let typePrompt = switch type {
        case .morning:
            "a brief morning intention to start the day with Stoic clarity"
        case .evening:
            "a brief evening reflection for Stoic self-examination"
        case .challenge:
            "a Stoic perspective on facing this challenge"
        case .gratitude:
            "a Stoic reflection on gratitude and acceptance"
        }

        let prompt = """
        Generate \(typePrompt).

        Context: \(context)

        Be brief (1-2 sentences). Be practical and actionable. No attribution needed.
        """

        return try await callGeminiWithModel(prompt: prompt, model: model)
    }

    // MARK: - Nano Banana Image Generation

    /// Generate a serene background image for a quote
    /// Optimized for watchOS - small file sizes, appropriate dimensions
    func generateQuoteBackground(
        quote: StoicQuote,
        style: ImageStyle = .stoic,
        aspectRatio: ImageAspectRatio = .watch
    ) async throws -> GeneratedImage {

        let prompt = """
        Create a meditative background image for a Stoic philosophy app on Apple Watch.

        Style: \(style.prompt)
        Mood: contemplative, peaceful, inspiring inner strength
        Quote context: "\(quote.text.prefix(50))..." by \(quote.author)

        IMPORTANT:
        - NO TEXT in the image - pure visual atmosphere
        - Simple, not cluttered - this is for a tiny watch screen
        - Calm colors that won't distract from text overlay
        - High contrast edges for readability

        Aspect ratio: \(aspectRatio.rawValue)
        """

        return try await generateImage(prompt: prompt, style: style, aspectRatio: aspectRatio)
    }

    /// Generate a complication background (small, simple)
    func generateComplicationBackground(
        mood: String = "calm stoic wisdom"
    ) async throws -> GeneratedImage {

        let prompt = """
        Create a tiny, simple background for an Apple Watch complication.

        Theme: \(mood)
        Style: minimalist, gradient, subtle texture
        Size: Very small (watch complication)

        IMPORTANT:
        - Extremely simple - just colors/gradients
        - NO text, NO complex imagery
        - High contrast for readability
        - Calming, not distracting

        Aspect ratio: 1:1
        """

        return try await generateImage(prompt: prompt, style: .minimal, aspectRatio: .square)
    }

    /// Generate ambient art for a Stoic concept
    func generateStoicArt(
        concept: String,
        style: ImageStyle = .cosmic
    ) async throws -> GeneratedImage {

        let prompt = """
        Create atmospheric art representing the Stoic concept: "\(concept)"

        Style: \(style.prompt)

        Make it:
        - Visually striking but meditative
        - Abstract enough to inspire contemplation
        - Suitable for a wellness/philosophy app
        - NO text in the image

        Aspect ratio: 7:9 (Apple Watch screen)
        """

        return try await generateImage(prompt: prompt, style: style, aspectRatio: .watch)
    }

    // MARK: - Personalized Stoic Stories

    /// Generate a short, personalized Stoic story tailored to user's context
    /// Uses Gemini 3 Pro for deeper narrative understanding
    func generatePersonalizedStory(
        userContext: String,
        storyType: StoryType = .parable,
        maxLength: Int = 300
    ) async throws -> PersonalizedStory {

        let prompt = """
        You are a master Stoic storyteller. Create a brief, powerful \(storyType.description) for this person.

        USER CONTEXT:
        \(userContext)

        STORY REQUIREMENTS:
        - Maximum \(maxLength) characters (this is for Apple Watch!)
        - Must directly address their specific situation
        - Include practical Stoic wisdom they can apply TODAY
        - If they're a \(extractProfession(from: userContext)), use relatable scenarios
        - End with a clear, actionable insight

        STYLE:
        \(storyType.styleGuidance)

        FORMAT: Return ONLY the story, no metadata or explanation.
        """

        let storyText = try await callGeminiWithModel(prompt: prompt, model: reasoningModel)

        // Generate a title for the story
        let titlePrompt = "Create a 2-4 word title for this Stoic parable (no quotes): \(storyText.prefix(100))"
        let title = try await callGeminiWithModel(prompt: titlePrompt, model: model)

        return PersonalizedStory(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: storyText,
            type: storyType,
            createdAt: Date(),
            userContextSnapshot: String(userContext.prefix(200))
        )
    }

    /// Generate a daily personalized story based on dynamic context
    func generateDailyStory(
        profile: UserProfile,
        dynamicContext: DynamicContext
    ) async throws -> PersonalizedStory {

        // Build rich context for personalization
        let storyContext = """
        ABOUT THE PRACTITIONER:
        - Name: \(profile.name.isEmpty ? "the practitioner" : profile.name)
        - Profession: \(profile.profession.displayName)
        - Primary focus: \(profile.currentFocus.displayName)
        - Life situations: \(profile.lifeContext.map { $0.displayName }.joined(separator: ", "))
        - Stoic goals: \(profile.stoicGoals.map { $0.displayName }.joined(separator: ", "))
        - Preferred philosopher: \(profile.preferredPhilosopher.displayName)

        CURRENT STATE:
        - Mood trend: \(dynamicContext.currentMoodTrend.description)
        - Pressing challenges: \(dynamicContext.urgentChallenges.joined(separator: ", "))
        - Growth areas: \(dynamicContext.growthAreas.joined(separator: ", "))
        - Recent wins: \(dynamicContext.recentWins.joined(separator: ", "))
        - Today's suggested focus: \(dynamicContext.suggestedFocus)

        RELEVANT THEMES FOR THEIR PROFESSION:
        \(profile.profession.relevantThemes.joined(separator: "\n- "))

        STOIC TEACHINGS FOR THEIR FOCUS:
        \(profile.currentFocus.stoicTeachings.joined(separator: "\n- "))
        """

        // Select story type based on mood
        let storyType: StoryType = switch dynamicContext.currentMoodTrend {
        case .struggling, .overwhelmed, .anxious:
            .comfortingWisdom
        case .improving, .grateful:
            .inspiringChallenge
        case .peaceful, .stable:
            .deepReflection
        case .neutral:
            .parable
        }

        return try await generatePersonalizedStory(
            userContext: storyContext,
            storyType: storyType,
            maxLength: 350
        )
    }

    /// Enhanced Marcus consultation with full dynamic context
    func consultMarcusWithContext(
        userMessage: String,
        profile: UserProfile,
        dynamicContext: DynamicContext,
        conversationHistory: [(role: String, content: String)] = []
    ) async throws -> String {

        let systemPrompt = """
        You are Marcus Aurelius, speaking to \(profile.name.isEmpty ? "a fellow seeker" : profile.name).

        ABOUT THEM:
        - They are \(profile.contextSummary)
        - Currently: \(dynamicContext.currentMoodTrend.description)
        - Working through: \(dynamicContext.urgentChallenges.joined(separator: ", "))
        - They resonate with \(profile.preferredPhilosopher.displayName)

        YOUR APPROACH TODAY:
        \(dynamicContext.currentMoodTrend.stoicApproach)

        YOUR VOICE:
        - Warm but direct - speak as a friend
        - Reference THEIR specific situation (profession, challenges)
        - Brief for watchOS - 2-4 sentences maximum
        - Share from YOUR experience when relevant
        - Focus on what they can CONTROL
        """

        let prompt = """
        \(systemPrompt)

        \(conversationHistory.isEmpty ? "" : "Previous exchange:\n" + conversationHistory.suffix(4).map { "\($0.role): \($0.content)" }.joined(separator: "\n"))

        They say: "\(userMessage)"

        Marcus, respond with personalized wisdom:
        """

        return try await callGeminiWithModel(prompt: prompt, model: reasoningModel)
    }

    /// Helper to extract profession from context string
    private func extractProfession(from context: String) -> String {
        let professions = ["healthcare professional", "business professional", "tech worker", "educator",
                          "creative professional", "legal professional", "military/veteran", "public servant",
                          "student", "full-time parent", "retiree", "professional"]
        for profession in professions {
            if context.lowercased().contains(profession.lowercased()) {
                return profession
            }
        }
        return "practitioner"
    }

    /// Core image generation method using Nano Banana models
    private func generateImage(
        prompt: String,
        style: ImageStyle,
        aspectRatio: ImageAspectRatio
    ) async throws -> GeneratedImage {

        // Note: Gemini API requires API key as query parameter (Google's API design)
        // Secure over HTTPS; key retrieved from Secrets.plist (not hardcoded)
        let urlString = "\(baseURL)/models/\(imageModel.id):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Images take longer

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "imageConfig": [
                    "aspectRatio": aspectRatio.rawValue
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw LLMError.requestFailed(statusCode: statusCode)
        }

        // Parse image from response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw LLMError.invalidResponse
        }

        // Find the image part (inlineData)
        for part in parts {
            if let inlineData = part["inlineData"] as? [String: Any],
               let base64String = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: base64String) {
                let mimeType = inlineData["mimeType"] as? String ?? "image/png"
                return GeneratedImage(
                    data: imageData,
                    mimeType: mimeType,
                    prompt: prompt,
                    style: style
                )
            }
        }

        throw LLMError.invalidResponse
    }

    /// Call Gemini with a specific model (for reasoning vs fast tasks)
    private func callGeminiWithModel(prompt: String, model: LLMModel) async throws -> String {
        let urlString = "\(baseURL)/models/\(model.id):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": model.maxTokens > 0 ? model.maxTokens : 500,
                "topP": 0.9
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw LLMError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        // Guard against empty quote array
        guard !quotes.isEmpty else {
            // Return a hardcoded fallback quote if array is empty
            return StoicQuote(
                id: "fallback_epictetus_001",
                text: "It's not what happens to you, but how you react to it that matters.",
                author: "Epictetus",
                book: "Enchiridion",
                contexts: ["control", "perspective", "response"],
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
