//
//  BoxBreathingDisplayView.swift
//  Stoic Companion
//
//  Box breathing exercise matching HTML mockup design
//  Features: 4-phase breathing (Inhale→Hold→Exhale→Hold), haptic feedback, session tracking
//

import SwiftUI

// MARK: - Breath Phase

enum BreathPhase: CaseIterable {
    case inhale
    case hold1
    case exhale
    case hold2

    var label: String {
        switch self {
        case .inhale: return "Inhale"
        case .hold1, .hold2: return "Hold"
        case .exhale: return "Exhale"
        }
    }

    var duration: Double { 4.0 }

    var color: Color {
        switch self {
        case .inhale: return Color(hex: "0A84FF")  // Blue
        case .hold1: return Color(hex: "30D158")   // Green
        case .exhale: return Color(hex: "5e5ce6")  // Purple
        case .hold2: return Color(hex: "FF9F0A")   // Orange
        }
    }

    var next: BreathPhase {
        let all = BreathPhase.allCases
        let currentIndex = all.firstIndex(of: self)!
        let nextIndex = (currentIndex + 1) % all.count
        return all[nextIndex]
    }
}

// MARK: - Box Breathing Display

struct BoxBreathingDisplayView: View {
    @State private var currentPhase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    @State private var sessionDuration: TimeInterval = 0
    @State private var cycleCount: Int = 0
    @State private var isActive = true
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    isActive = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0A84FF"))
                }

                Spacer()

                Text("Box Breathing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Spacer()

            // Main breathing visualization
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(currentPhase.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .blur(radius: 8)
                    .scaleEffect(scale * 1.1)

                // Main breathing circle
                Circle()
                    .stroke(
                        currentPhase.color,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: currentPhase.color.opacity(0.5), radius: 15)

                // Inner indicator dots (flower petal effect)
                ForEach(0..<6) { index in
                    Circle()
                        .fill(currentPhase.color.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: -50 * scale)
                        .rotationEffect(.degrees(Double(index) * 60 + rotation))
                }

                // Phase text
                VStack(spacing: 4) {
                    Text(currentPhase.label)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(Int(currentPhase.duration))s")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Session stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(cycleCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("Cycles")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(formatDuration(sessionDuration))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("Time")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Subtle gradient background that shifts with phase
            RadialGradient(
                colors: [
                    currentPhase.color.opacity(0.05),
                    Color.black
                ],
                center: .center,
                startRadius: 50,
                endRadius: 200
            )
        )
        .onAppear {
            startBreathing()
            startSessionTimer()
        }
        .onDisappear {
            isActive = false
            timer?.invalidate()
        }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        animate()
    }

    private func animate() {
        guard isActive else { return }

        let duration = currentPhase.duration

        // Haptic feedback for phase change
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif

        // Scale animation based on phase
        withAnimation(.easeInOut(duration: duration)) {
            switch currentPhase {
            case .inhale:
                scale = 1.3  // Expand
            case .hold1:
                scale = 1.3  // Stay expanded
            case .exhale:
                scale = 0.7  // Contract
            case .hold2:
                scale = 0.7  // Stay contracted
            }
        }

        // Subtle rotation
        withAnimation(.linear(duration: duration)) {
            rotation += 90
        }

        // Move to next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if currentPhase == .hold2 {
                cycleCount += 1
            }
            currentPhase = currentPhase.next
            animate()
        }
    }

    // MARK: - Session Timer

    private func startSessionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isActive {
                sessionDuration += 1
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Breathing Complete View

struct BreathingCompleteView: View {
    let cyclesCompleted: Int
    let duration: TimeInterval

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Checkmark
            if showCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "30D158"))
                    .transition(.scale.combined(with: .opacity))
            }

            Text("Session Complete")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            // Stats
            VStack(spacing: 8) {
                HStack {
                    Text("Cycles:")
                        .foregroundColor(.secondary)
                    Text("\(cyclesCompleted)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Duration:")
                        .foregroundColor(.secondary)
                    Text(formatDuration(duration))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 14))

            Spacer()

            Text("You are calm and centered")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .italic()
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showCheckmark = true
            }

            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Compact Breathing Card

struct BreathingCard: View {
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "0A84FF"), lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulse)

                Text("🫁")
                    .font(.system(size: 20))
            }

            Text("Breathing")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "1c1c1e"))
        .cornerRadius(24)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = 1.2
            }
        }
    }
}

// MARK: - Previews

#Preview("Box Breathing") {
    BoxBreathingDisplayView()
}

#Preview("Breathing Complete") {
    BreathingCompleteView(cyclesCompleted: 5, duration: 120)
}

#Preview("Breathing Card") {
    BreathingCard()
        .frame(width: 150, height: 150)
        .background(Color.black)
}
