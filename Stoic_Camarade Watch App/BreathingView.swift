//
//  BreathingView.swift
//  StoicCamarade Watch App
//
//  Box breathing and other breathing exercises
//  Part of the Nano Banana Pro Series aesthetic.
//

import SwiftUI
import WatchKit

// MARK: - Breathing Pattern

enum BreathingPattern: String, CaseIterable {
    case box = "Box Breathing"
    case calm = "4-7-8 Calm"
    case energize = "Quick Energize"

    var phases: [(name: String, duration: Int)] {
        switch self {
        case .box:
            return [("Inhale", 4), ("Hold", 4), ("Exhale", 4), ("Hold", 4)]
        case .calm:
            return [("Inhale", 4), ("Hold", 7), ("Exhale", 8)]
        case .energize:
            return [("Inhale", 2), ("Exhale", 2)]
        }
    }

    var description: String {
        switch self {
        case .box: return "Equal breathing for focus"
        case .calm: return "Deep relaxation technique"
        case .energize: return "Quick energy boost"
        }
    }

    var icon: String {
        switch self {
        case .box: return "square"
        case .calm: return "moon.fill"
        case .energize: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .box: return PremiumAssets.Colors.electricBlue
        case .calm: return PremiumAssets.Colors.moonPurple
        case .energize: return PremiumAssets.Colors.vibrantOrange
        }
    }
}

// MARK: - Breathing View

struct BreathingView: View {
    @State private var selectedPattern: BreathingPattern = .box
    @State private var isActive = false
    @State private var currentPhaseIndex = 0
    @State private var secondsRemaining = 0
    @State private var cyclesCompleted = 0
    @State private var timer: Timer?
    @State private var breathScale: CGFloat = 1.0
    @State private var animateBg = false

    private let totalCycles = 4

    var body: some View {
        ZStack {
            // Nano Banana Pro: Animated Deep Background
            PremiumBackgroundView()
            
            Group {
                if isActive {
                    activeBreathingView
                } else {
                    selectionView
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(isActive)
    }

    // MARK: - Selection View

    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // View Header
                VStack(spacing: 6) {
                    Text("BREATHWORK")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                        .tracking(2)
                    
                    Text("Select your pattern")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)

                VStack(spacing: 10) {
                    ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                        PatternCard(pattern: pattern, isSelected: pattern == selectedPattern) {
                            WKInterfaceDevice.current().play(.click)
                            selectedPattern = pattern
                        }
                    }
                }

                // Start button
                Button(action: startBreathing) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .black))
                        Text("BEGIN SESSION")
                            .font(.system(size: 12, weight: .black))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedPattern.color)
                    .cornerRadius(12)
                    .shadow(color: selectedPattern.color.opacity(0.4), radius: 10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 10)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Active Breathing View

    private var activeBreathingView: some View {
        VStack(spacing: 20) {
            // Cycle Progress
            HStack(spacing: 8) {
                ForEach(0..<totalCycles, id: \.self) { index in
                    Capsule()
                        .fill(index < cyclesCompleted ? selectedPattern.color : Color.white.opacity(0.1))
                        .frame(width: 14, height: 4)
                        .shadow(color: index < cyclesCompleted ? selectedPattern.color.opacity(0.5) : .clear, radius: 4)
                }
            }

            // Breathing circle
            ZStack {
                // Background aura: Pulsing
                Circle()
                    .fill(selectedPattern.color.opacity(0.15))
                    .frame(width: 150 * breathScale, height: 150 * breathScale)
                    .blur(radius: 25)
                    .opacity(breathScale > 1.0 ? 0.6 : 0.3)
                
                // Track ring: Glassy
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 140, height: 140)

                // Animated breathing circle: Radial Gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [selectedPattern.color.opacity(0.6), selectedPattern.color.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 110 * breathScale, height: 110 * breathScale)
                    .animation(.easeInOut(duration: Double(currentPhaseDuration)), value: breathScale)
                    .blur(radius: 4)

                // Timer display
                VStack(spacing: 4) {
                    Text("\(secondsRemaining)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)

                    Text(currentPhaseName.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(selectedPattern.color)
                        .tracking(1.5)
                }
            }
            .frame(width: 160, height: 160)

            // Pattern name
            Text(selectedPattern.rawValue.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.gray.opacity(0.8))
                .tracking(1)

            // Stop button
            Button(action: {
                WKInterfaceDevice.current().play(.directionDown)
                stopBreathing()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var currentPhaseName: String {
        guard currentPhaseIndex < selectedPattern.phases.count else { return "" }
        return selectedPattern.phases[currentPhaseIndex].name
    }

    private var currentPhaseDuration: Int {
        guard currentPhaseIndex < selectedPattern.phases.count else { return 4 }
        return selectedPattern.phases[currentPhaseIndex].duration
    }

    // MARK: - Actions

    private func startBreathing() {
        WKInterfaceDevice.current().play(.start)
        isActive = true
        cyclesCompleted = 0
        currentPhaseIndex = 0
        startPhase()
    }

    private func startPhase() {
        guard cyclesCompleted < totalCycles else {
            completeBreathing()
            return
        }

        guard currentPhaseIndex < selectedPattern.phases.count else {
            // Cycle complete
            cyclesCompleted += 1
            currentPhaseIndex = 0
            startPhase()
            return
        }

        let phase = selectedPattern.phases[currentPhaseIndex]
        secondsRemaining = phase.duration

        // Update breath scale based on phase
        if phase.name.contains("Inhale") {
            breathScale = 1.3
            WKInterfaceDevice.current().play(.directionUp)
        } else if phase.name.contains("Exhale") {
            breathScale = 0.7
            WKInterfaceDevice.current().play(.directionDown)
        } else {
            // Hold
            WKInterfaceDevice.current().play(.click)
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if secondsRemaining > 1 {
                secondsRemaining -= 1
            } else {
                timer?.invalidate()
                currentPhaseIndex += 1
                startPhase()
            }
        }
    }

    private func stopBreathing() {
        timer?.invalidate()
        timer = nil
        isActive = false
        breathScale = 1.0
    }

    private func completeBreathing() {
        WKInterfaceDevice.current().play(.success)
        timer?.invalidate()
        timer = nil
        isActive = false
        breathScale = 1.0
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: BreathingPattern
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(pattern.color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: pattern.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(pattern.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Text(pattern.description)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(pattern.color)
                }
            }
            .padding(12)
            .background(
                PremiumAssets.GlassBackdrop(
                    cornerRadius: 16,
                    opacity: isSelected ? 0.12 : 0.05,
                    borderColor: isSelected ? pattern.color.opacity(0.4) : .white.opacity(0.08)
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BreathingView()
}
