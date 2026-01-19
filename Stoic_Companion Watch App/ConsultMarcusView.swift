//
//  ConsultMarcusView.swift
//  StoicCompanion Watch App
//
//  AI-powered conversation with Marcus Aurelius persona
//

import SwiftUI
import Combine
import WatchKit

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// MARK: - Marcus Consultant

class MarcusConsultant: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    private let llmService: LLMService
    private let geminiService: GeminiService?  // Enhanced Gemini 3 Pro for deep reasoning

    // Dynamic context for personalization
    private let profileManager = ProfileManager()
    private let dynamicContextManager = DynamicUserContextManager.shared
    private let journalManager = JournalManager.shared

    init() {
        self.llmService = LLMServiceFactory.createService()

        // If using Gemini, also create enhanced reasoning service for deeper conversations
        if Config.llmProvider == .gemini {
            self.geminiService = LLMServiceFactory.createGeminiReasoningService()
        } else {
            self.geminiService = nil
        }

        // Refresh dynamic context if needed
        Task {
            if dynamicContextManager.needsRefresh {
                await dynamicContextManager.refreshContextWithAI(
                    profile: profileManager.profile,
                    journalManager: journalManager
                )
            }
        }
    }

    func sendMessage(_ userMessage: String) async {
        // Add user message
        let userChat = ChatMessage(content: userMessage, isUser: true)
        await MainActor.run {
            messages.append(userChat)
            isLoading = true
        }

        // Get Marcus's response with personalization
        do {
            let response = try await getMarcusResponse(to: userMessage)
            let marcusChat = ChatMessage(content: response, isUser: false)
            await MainActor.run {
                messages.append(marcusChat)
                isLoading = false
            }
        } catch {
            let errorChat = ChatMessage(content: "I cannot respond at this moment. Remember: what is in your control is your own response.", isUser: false)
            await MainActor.run {
                messages.append(errorChat)
                isLoading = false
            }
        }
    }

    private func getMarcusResponse(to message: String) async throws -> String {
        // Use enhanced Gemini 3 Pro reasoning with full personalization if available
        if let gemini = geminiService {
            let history = messages.map { msg -> (role: String, content: String) in
                (msg.isUser ? "user" : "model", msg.content)
            }

            // Use personalized consultation if user has completed onboarding
            if profileManager.profile.onboardingCompleted {
                return try await gemini.consultMarcusWithContext(
                    userMessage: message,
                    profile: profileManager.profile,
                    dynamicContext: dynamicContextManager.dynamicContext,
                    conversationHistory: history
                )
            }

            // Fallback to basic consultation
            return try await gemini.consultMarcus(
                userMessage: message,
                conversationHistory: history
            )
        }

        // Fallback to standard LLM service prompt with context
        let contextInfo = profileManager.profile.onboardingCompleted
            ? "Context: The user is \(profileManager.profile.contextSummary). "
            : ""

        let prompt = """
        You are Marcus Aurelius, Roman Emperor and Stoic philosopher. Respond to the following concern with wisdom from Stoic philosophy. Be concise (2-3 sentences max), direct, and compassionate. Speak as Marcus would - with gravity, wisdom, and practical advice. Reference Stoic concepts like: what is in our control vs not, the present moment, virtue, acceptance, and rational thinking.

        \(contextInfo)
        User's concern: \(message)

        Respond as Marcus Aurelius:
        """

        let response = try await llmService.generateResponse(prompt: prompt)
        return response
    }

    func clearChat() {
        messages.removeAll()
    }
}

// Note: generateResponse is now properly implemented in OpenAIService.swift
// The LLMService protocol extension below provides fallback responses only if the API fails

// MARK: - Consult Marcus View

struct ConsultMarcusView: View {
    @StateObject private var consultant = MarcusConsultant()
    @State private var inputText = ""
    @State private var showingVoiceInput = false

    // Quick prompts
    private let quickPrompts = [
        "Feeling overwhelmed...",
        "I'm anxious about...",
        "I can't control...",
        "I'm angry at..."
    ]

    @State private var gradientStart = UnitPoint.topLeading
    @State private var gradientEnd = UnitPoint.bottomTrailing

    var body: some View {
        ZStack {
            // Nano Banana Pro: Animated Deep Background
            PremiumBackgroundView()
            
            VStack(spacing: 0) {
                if consultant.messages.isEmpty {
                    welcomeView
                } else {
                    chatView
                }

                inputArea
            }
        }
        .navigationTitle("Marcus")
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Marcus portrait
                PremiumAssets.MarcusAvatar(size: 80)
                    .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.4), radius: 15)

                VStack(spacing: 4) {
                    Text("CONSULT MARCUS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                        .tracking(2)
                    
                    Text("Share your burden. Receive stoic wisdom.")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                // Quick prompts
                VStack(spacing: 10) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            Task { await consultant.sendMessage(prompt) }
                        }) {
                            Text(prompt)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(PremiumAssets.GlassBackdrop(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }

    // MARK: - Chat View

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(consultant.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if consultant.isLoading {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: consultant.messages.count) { _, _ in
                if let lastMessage = consultant.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 8) {
            // Voice input button
            Button(action: { 
                WKInterfaceDevice.current().play(.click)
                showingVoiceInput = true 
            }) {
                ZStack {
                    Circle()
                        .fill(PremiumAssets.Colors.electricBlue.opacity(0.2))
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundColor(PremiumAssets.Colors.electricBlue)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(PlainButtonStyle())

            // Text field
            TextField("Speak...", text: $inputText)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(PremiumAssets.GlassBackdrop(cornerRadius: 19))

            // Send button
            if !inputText.isEmpty {
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    let message = inputText
                    inputText = ""
                    Task { await consultant.sendMessage(message) }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                        .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.3), radius: 5)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.4)
                .blur(radius: 10)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if !message.isUser {
                    HStack(spacing: 4) {
                        Image(systemName: "person.bust.fill")
                            .font(.system(size: 8))
                        Text("MARCUS")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1)
                    }
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                    .padding(.leading, 4)
                }

                Text(message.content)
                    .font(.system(size: 12, weight: .medium, design: message.isUser ? .default : .serif))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(12)
                    .background(
                        PremiumAssets.GlassBackdrop(
                            cornerRadius: 16,
                            opacity: message.isUser ? 0.2 : 0.1,
                            borderColor: message.isUser ? PremiumAssets.Colors.electricBlue.opacity(0.3) : .white.opacity(0.1)
                        )
                    )
            }

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onAppear { animating = true }
    }
}

#Preview {
    NavigationView {
        ConsultMarcusView()
    }
}
