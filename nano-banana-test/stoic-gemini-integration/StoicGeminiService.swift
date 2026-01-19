/**
 * StoicGeminiService.swift
 * Gemini AI integration for Stoic Companion
 *
 * This can be used in both watchOS (limited) and iOS companion app (full features)
 */

import Foundation

// MARK: - Gemini Models

enum GeminiModel: String {
    case flash = "gemini-2.5-flash"           // Fast, cheap - good for quote selection
    case flashImage = "gemini-2.5-flash-image" // Image generation
    case pro = "gemini-3-pro-preview"          // Complex reasoning
}

// MARK: - Stoic Gemini Service

class StoicGeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    init(apiKey: String = Config.geminiKey) {
        self.apiKey = apiKey
    }

    // MARK: - 1. Enhanced Quote Selection (watchOS compatible)

    /// Select the most appropriate quote based on context
    /// Uses gemini-2.5-flash for speed and low cost
    func selectQuote(
        context: HealthContext,
        availableQuotes: [StoicQuote]
    ) async throws -> StoicQuote {

        let prompt = """
        You are a Stoic wisdom curator for an Apple Watch app.

        USER CONTEXT:
        - Heart Rate: \(context.heartRate ?? 0) BPM
        - Stress Level: \(context.stressLevel)
        - Time of Day: \(context.timeOfDay ?? "unknown")
        - Activity: \(context.isActive ? "active" : "resting")
        - Primary Need: \(context.primaryContext)

        AVAILABLE QUOTES:
        \(availableQuotes.prefix(20).map { "[\($0.id)] \($0.text) — \($0.author)" }.joined(separator: "\n"))

        Select the SINGLE best quote ID for this person's current state.
        Reply with ONLY the quote ID, nothing else.
        """

        let response = try await generateText(prompt: prompt, model: .flash)
        let quoteId = response.trimmingCharacters(in: .whitespacesAndNewlines)

        return availableQuotes.first { $0.id == quoteId } ?? availableQuotes.randomElement()!
    }

    // MARK: - 2. Consult Marcus (watchOS compatible)

    /// Chat with a Stoic philosopher about your situation
    func consultMarcus(
        userMessage: String,
        conversationHistory: [ChatMessage] = []
    ) async throws -> String {

        let systemPrompt = """
        You are Marcus Aurelius, the Stoic philosopher-emperor.
        Respond to the user's concern with wisdom from your Meditations.
        Keep responses SHORT (2-3 sentences max) - this is for Apple Watch.
        Be warm but practical. Focus on what they can control.
        """

        var messages = conversationHistory.map { msg in
            ["role": msg.role, "content": msg.content]
        }
        messages.append(["role": "user", "content": userMessage])

        return try await generateText(
            prompt: userMessage,
            systemPrompt: systemPrompt,
            model: .flash
        )
    }

    // MARK: - 3. Generate Stoic Reflection (watchOS compatible)

    /// Generate a brief stoic reflection based on context
    func generateReflection(for context: String) async throws -> String {
        let prompt = """
        Generate a brief (1-2 sentences) Stoic reflection for someone who is: \(context)

        Make it practical and actionable. No attribution needed.
        """

        return try await generateText(prompt: prompt, model: .flash)
    }

    // MARK: - 4. Generate Quote Background (iOS Companion App)

    /// Generate a serene background image for a quote
    /// ⚠️ Use only on iOS - too heavy for watchOS
    func generateQuoteBackground(
        quote: StoicQuote,
        style: BackgroundStyle = .serene
    ) async throws -> Data {

        let stylePrompts: [BackgroundStyle: String] = [
            .serene: "serene, peaceful, soft gradients, zen garden aesthetic",
            .stoic: "ancient Rome, marble columns, classical architecture, warm sunset",
            .nature: "mountains at dawn, mist, tranquil lake, natural beauty",
            .minimal: "abstract, minimalist, geometric shapes, muted earth tones",
            .cosmic: "starry night sky, galaxy, contemplative, vast universe"
        ]

        let prompt = """
        Create a meditative background image for a Stoic philosophy quote.
        Style: \(stylePrompts[style] ?? "serene")
        Mood: contemplative, peaceful, inspiring inner strength
        Quote context: "\(quote.text.prefix(50))..." by \(quote.author)

        NO TEXT in the image. Pure visual atmosphere.
        Aspect ratio: 9:16 (phone wallpaper)
        """

        return try await generateImage(prompt: prompt, aspectRatio: "9:16")
    }

    // MARK: - 5. Analyze Photo for Stoic Wisdom (iOS Companion App)

    /// User uploads a photo of something bothering them
    /// AI analyzes and provides stoic perspective
    /// ⚠️ Use only on iOS
    func analyzeForStoicWisdom(
        imageData: Data,
        userContext: String?
    ) async throws -> StoicAnalysis {

        let prompt = """
        Analyze this image from a Stoic philosophy perspective.
        \(userContext.map { "User says: \($0)" } ?? "")

        Provide:
        1. What you observe (1 sentence)
        2. What a Stoic would focus on - what's in their control (1-2 sentences)
        3. A relevant Stoic principle to apply (1 sentence)
        4. A brief actionable suggestion (1 sentence)

        Return as JSON:
        {
          "observation": "...",
          "stoicFocus": "...",
          "principle": "...",
          "suggestion": "..."
        }
        """

        let response = try await analyzeImage(imageData: imageData, prompt: prompt)
        return try JSONDecoder().decode(StoicAnalysis.self, from: response.data(using: .utf8)!)
    }

    // MARK: - 6. Generate Shareable Quote Card (iOS Companion App)

    /// Generate a beautiful quote card image for sharing
    /// ⚠️ Use only on iOS
    func generateShareableQuoteCard(
        quote: StoicQuote
    ) async throws -> Data {

        let prompt = """
        Create an elegant, shareable quote card image.

        The image should have:
        - A serene, classical background (soft marble texture, laurel leaves)
        - Space in the center for text overlay
        - Warm, sophisticated color palette (ivory, gold accents, deep green)
        - Subtle decorative elements (Greek key pattern border, olive branches)

        Style: editorial, museum-quality, timeless elegance
        Aspect ratio: 1:1 (Instagram)

        NO TEXT - leave space for quote overlay in app.
        """

        return try await generateImage(prompt: prompt, aspectRatio: "1:1")
    }

    // MARK: - Private API Methods

    private func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        model: GeminiModel = .flash
    ) async throws -> String {

        let url = URL(string: "\(baseURL)/\(model.rawValue):generateContent?key=\(apiKey)")!

        var contents: [[String: Any]] = [
            ["role": "user", "parts": [["text": prompt]]]
        ]

        var body: [String: Any] = ["contents": contents]

        if let system = systemPrompt {
            body["systemInstruction"] = ["parts": [["text": system]]]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.invalidResponse
        }

        return text
    }

    private func generateImage(prompt: String, aspectRatio: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/\(GeminiModel.flashImage.rawValue):generateContent?key=\(apiKey)")!

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "imageConfig": ["aspectRatio": aspectRatio]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let inlineData = parts.first?["inlineData"] as? [String: Any],
              let base64 = inlineData["data"] as? String else {
            throw GeminiError.noImageGenerated
        }

        return Data(base64Encoded: base64)!
    }

    private func analyzeImage(imageData: Data, prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/\(GeminiModel.flash.rawValue):generateContent?key=\(apiKey)")!

        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inlineData": ["mimeType": "image/jpeg", "data": base64]]
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.invalidResponse
        }

        return text
    }
}

// MARK: - Supporting Types

enum BackgroundStyle {
    case serene, stoic, nature, minimal, cosmic
}

struct StoicAnalysis: Codable {
    let observation: String
    let stoicFocus: String
    let principle: String
    let suggestion: String
}

struct ChatMessage {
    let role: String  // "user" or "model"
    let content: String
}

enum GeminiError: Error {
    case invalidResponse
    case noImageGenerated
    case networkError
}
