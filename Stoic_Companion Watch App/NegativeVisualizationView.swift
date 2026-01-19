//
//  NegativeVisualizationView.swift
//  StoicCompanion Watch App
//
//  Premeditatio Malorum - Stoic practice of imagining loss to build gratitude
//

import SwiftUI

// MARK: - Visualization Prompts

struct VisualizationPrompt: Identifiable {
    let id = UUID()
    let category: String
    let prompt: String
    let reflection: String
    let icon: String
    let color: Color
}

// MARK: - Negative Visualization View

struct NegativeVisualizationView: View {
    @State private var currentPrompt: VisualizationPrompt?
    @State private var isVisualizating = false
    @State private var showingCompletion = false
    @State private var timer: Timer?
    @State private var secondsRemaining = 60

    private let visualizationDuration = 60 // 1 minute

    private let prompts = [
        VisualizationPrompt(
            category: "Relationships",
            prompt: "Imagine losing someone you love. Feel the absence. Now return to the present - they are here.",
            reflection: "Appreciate their presence today.",
            icon: "heart.fill",
            color: .red
        ),
        VisualizationPrompt(
            category: "Health",
            prompt: "Imagine losing your ability to walk freely. Feel the limitation. Now return - you can move.",
            reflection: "Use your body with gratitude.",
            icon: "figure.walk",
            color: .green
        ),
        VisualizationPrompt(
            category: "Home",
            prompt: "Imagine losing your home and shelter. Feel the vulnerability. Now return - you have refuge.",
            reflection: "Your shelter is a gift.",
            icon: "house.fill",
            color: .blue
        ),
        VisualizationPrompt(
            category: "Sight",
            prompt: "Imagine losing your vision. Feel the darkness. Now return - you can see the world.",
            reflection: "Each sight is precious.",
            icon: "eye.fill",
            color: .purple
        ),
        VisualizationPrompt(
            category: "Freedom",
            prompt: "Imagine losing your freedom of choice. Feel the constraint. Now return - you are free.",
            reflection: "Exercise your freedom wisely.",
            icon: "bird.fill",
            color: .orange
        ),
        VisualizationPrompt(
            category: "Today",
            prompt: "Imagine this is your last day. What would you regret not doing? Now return - you have time.",
            reflection: "Do that thing today.",
            icon: "sun.max.fill",
            color: .yellow
        ),
    ]

    var body: some View {
        Group {
            if isVisualizating {
                visualizationView
            } else if showingCompletion {
                completionView
            } else {
                startView
            }
        }
        .navigationTitle("Neg. Vis.")
    }

    // MARK: - Start View

    private var startView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }

                Text("Negative Visualization")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text("Premeditatio Malorum: Imagine loss to cultivate gratitude for what you have.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // Begin button
                Button(action: startVisualization) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Begin")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                // AI-powered personal visualization
                if isGeneratingPrompt {
                    HStack {
                        ProgressView()
                        Text("AI creating...")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                    }
                } else {
                    aiVisualizationButton
                }

                // Quote
                Text("\"He robs present ills of their power who has perceived their coming beforehand.\"")
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.gray.opacity(0.7))
                    .italic()
                    .multilineTextAlignment(.center)

                Text("— Seneca")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            }
            .padding()
        }
    }

    // MARK: - Visualization View

    private var visualizationView: some View {
        VStack(spacing: 16) {
            if let prompt = currentPrompt {
                // Category
                HStack(spacing: 4) {
                    Image(systemName: prompt.icon)
                        .font(.system(size: 12))
                    Text(prompt.category)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(prompt.color)

                // Timer
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: CGFloat(secondsRemaining) / CGFloat(visualizationDuration))
                        .stroke(prompt.color, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(secondsRemaining)s")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                // Prompt
                Text(prompt.prompt)
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.4))
                    )

                // Skip button
                Button(action: completeVisualization) {
                    Text("Complete Early")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Visualization Complete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            if let prompt = currentPrompt {
                Text(prompt.reflection)
                    .font(.system(size: 12))
                    .foregroundColor(prompt.color)
                    .multilineTextAlignment(.center)
            }

            Text("Return to your day with renewed gratitude.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                showingCompletion = false
                currentPrompt = nil
            }) {
                Text("Done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }

    // MARK: - Actions

    private func startVisualization() {
        currentPrompt = prompts.randomElement()
        secondsRemaining = visualizationDuration
        isVisualizating = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                completeVisualization()
            }
        }
    }

    private func completeVisualization() {
        timer?.invalidate()
        timer = nil
        isVisualizating = false
        showingCompletion = true
    }

    // MARK: - AI-Personalized Visualization (Premium Feature)

    @State private var showingAIVisualization = false
    @State private var aiPrompt: String = ""
    @State private var isGeneratingPrompt = false

    private var aiVisualizationButton: some View {
        Button(action: {
            Task { await generatePersonalizedVisualization() }
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI Personal")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func generatePersonalizedVisualization() async {
        await MainActor.run { isGeneratingPrompt = true }
        
        let llmService = LLMServiceFactory.createService()
        let prompt = """
        You are a Stoic meditation guide. Generate a unique and deeply personal negative visualization exercise.
        
        Create a prompt that helps someone:
        1. Imagine losing something they take for granted (be specific and evocative)
        2. Feel the absence deeply but briefly
        3. Return to gratitude for what they have now
        
        Write in second person ("Imagine..."). Keep it to 3 sentences maximum. Be poetic but grounded.
        Do NOT use cliches. Create something original and moving.
        """
        
        do {
            let response = try await llmService.generateResponse(prompt: prompt)
            await MainActor.run {
                aiPrompt = response
                currentPrompt = VisualizationPrompt(
                    category: "Personal",
                    prompt: response,
                    reflection: "This moment is precious. Live accordingly.",
                    icon: "sparkles",
                    color: .purple
                )
                isGeneratingPrompt = false
                startVisualization()
            }
        } catch {
            await MainActor.run {
                isGeneratingPrompt = false
            }
        }
    }
}

#Preview {
    NavigationView {
        NegativeVisualizationView()
    }
}
