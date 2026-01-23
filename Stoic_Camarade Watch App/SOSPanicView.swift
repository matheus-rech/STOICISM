//
//  SOSPanicView.swift
//  StoicCamarade Watch App
//
//  Emergency calm mode with breathing exercise
//  Part of the Nano Banana Pro Series aesthetic.
//

import SwiftUI
import WatchKit

// MARK: - SOS Panic View

struct SOSPanicView: View {
    @State private var currentPhase: BreathPhase = .ready
    @State private var breathCount = 0
    @State private var timer: Timer?
    @State private var progress: CGFloat = 0
    @State private var showingCompletion = false
    
    // Animation states
    @State private var animateSOS = false

    private let totalBreaths = 4

    enum BreathPhase: String {
        case ready = "READY"
        case breatheIn = "Breathe In..."
        case hold = "Hold..."
        case breatheOut = "Release..."
        case complete = "CALM RESTORED"
    }

    var body: some View {
        ZStack {
            // Nano Banana Pro Series: Animated Deep Gradient Background
            PremiumBackgroundView()

            if currentPhase == .ready {
                readyView
            } else if currentPhase == .complete {
                completionView
            } else {
                breathingView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateSOS = true
            }
        }
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 20) {
            // View Label
            Text("SOS RELIEF")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.red)
                .tracking(2)
                .padding(.top, 10)
            
            // SOS Circle (Premium Gradient)
            Button(action: {
                WKInterfaceDevice.current().play(.directionUp)
                startBreathing()
            }) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(animateSOS ? 1.1 : 1.0)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.red, Color(red: 0.4, green: 0, blue: 0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: .red.opacity(0.4), radius: 10)

                    Text("SOS")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(spacing: 8) {
                Text("Tap to Regain Control")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text("A Stoic mind remains unshakeable.")
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundColor(.gray)
                    .italic()
            }
            
            Spacer()
        }
    }

    // MARK: - Breathing View

    private var breathingView: some View {
        ZStack {
            // Pulsing Blurred Aura (Backdrop from Design)
            Circle()
                .fill(PremiumAssets.Colors.electricBlue.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .scaleEffect(progress > 0.5 ? 1.2 : 1.0)
                .animation(.easeInOut(duration: phaseDuration), value: currentPhase)

            VStack(spacing: 20) {
                // Phase Header
                Text("EMERGENCY BREATH")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(PremiumAssets.Colors.electricBlue)
                    .tracking(2)
                
                // Animated breathing circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 8)
                        .frame(width: 125, height: 125)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [PremiumAssets.Colors.electricBlue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 125, height: 125)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: PremiumAssets.Colors.electricBlue.opacity(0.3), radius: 10)

                    // Phase text
                    VStack(spacing: 4) {
                        Text(phaseText)
                            .font(.system(size: 14, weight: .black, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(Int((1.0 - progress) * phaseDuration))s")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }

                // Breath counter
                HStack(spacing: 8) {
                    ForEach(0..<totalBreaths, id: \.self) { index in
                        Circle()
                            .fill(index < breathCount ? PremiumAssets.Colors.electricBlue : Color.white.opacity(0.1))
                            .frame(width: 6, height: 6)
                            .shadow(color: index < breathCount ? PremiumAssets.Colors.electricBlue.opacity(0.5) : .clear, radius: 2)
                    }
                }

                // Cancel button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    stopBreathing()
                }) {
                    Text("EXIT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(PremiumAssets.Colors.successGreen)
                .shadow(color: PremiumAssets.Colors.successGreen.opacity(0.3), radius: 10)

            VStack(spacing: 4) {
                Text("STORM PASSED")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Your reason is your anchor.")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(PremiumAssets.Colors.successGreen)
            }

            // AI-generated personalized calm message
            if isLoadingCalm {
                ProgressView()
                    .tint(PremiumAssets.Colors.successGreen)
            } else {
                Text(calmMessage)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)
            }

            Button(action: { 
                WKInterfaceDevice.current().play(.success)
                currentPhase = .ready
                breathCount = 0 
            }) {
                Text("RETURN TO CALM")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(PremiumAssets.Colors.successGreen)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
            WKInterfaceDevice.current().play(.success)
            Task { await generateCalmMessage() }
        }
    }

    @State private var calmMessage = "You have power over your mind, not outside events."
    @State private var isLoadingCalm = false

    private func generateCalmMessage() async {
        await MainActor.run { isLoadingCalm = true }
        
        let llmService = LLMServiceFactory.createService()
        let prompt = """
        You are Marcus Aurelius. Someone just completed an emergency breathing exercise because they were feeling anxious or panicked. 
        
        Give them ONE short sentence (max 15 words) of stoic wisdom to carry forward. Be calming, grounding, and remind them of their inner strength.
        """
        
        do {
            let response = try await llmService.generateResponse(prompt: prompt)
            await MainActor.run {
                calmMessage = response
                isLoadingCalm = false
            }
        } catch {
            await MainActor.run {
                calmMessage = "The storm has passed. Your reason remains. Proceed with clarity."
                isLoadingCalm = false
            }
        }
    }

    // MARK: - Computed Properties

    private var phaseText: String {
        switch currentPhase {
        case .breatheIn: return "Inhale"
        case .hold: return "Pause"
        case .breatheOut: return "Exhale"
        default: return ""
        }
    }

    private var phaseDuration: Double {
        switch currentPhase {
        case .breatheIn: return 4.0
        case .hold: return 4.0
        case .breatheOut: return 4.0
        default: return 0.5
        }
    }

    // MARK: - Actions

    private func startBreathing() {
        breathCount = 0
        runBreathCycle()
    }

    private func runBreathCycle() {
        guard breathCount < totalBreaths else {
            currentPhase = .complete
            return
        }

        // Breathe In (4 seconds)
        currentPhase = .breatheIn
        progress = 0
        animateProgress(duration: 4.0) {
            // Hold (4 seconds)
            currentPhase = .hold
            progress = 0
            animateProgress(duration: 4.0) {
                // Breathe Out (4 seconds)
                currentPhase = .breatheOut
                progress = 0
                animateProgress(duration: 4.0) {
                    breathCount += 1
                    runBreathCycle()
                }
            }
        }
    }

    private func animateProgress(duration: Double, completion: @escaping () -> Void) {
        let steps = 100
        let interval = duration / Double(steps)
        var step = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            step += 1
            progress = CGFloat(step) / CGFloat(steps)

            if step >= steps {
                t.invalidate()
                completion()
            }
        }
    }

    private func stopBreathing() {
        timer?.invalidate()
        timer = nil
        currentPhase = .ready
        breathCount = 0
        progress = 0
    }
}

#Preview {
    SOSPanicView()
}
