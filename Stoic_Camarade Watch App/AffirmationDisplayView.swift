//
//  AffirmationDisplayView.swift
//  Stoic Camarade
//
//  Daily affirmation display matching HTML mockup design
//  Features: Beautiful gradients, pulsing glow, rotation system
//

import SwiftUI

// MARK: - Affirmation Model

struct DailyAffirmation: Identifiable {
    let id: String
    let text: String
    let category: AffirmationCategory
    let author: String?

    init(id: String = UUID().uuidString, text: String, category: AffirmationCategory, author: String? = nil) {
        self.id = id
        self.text = text
        self.category = category
        self.author = author
    }
}

enum AffirmationCategory {
    case discipline
    case calm
    case courage
    case wisdom

    var gradient: [Color] {
        switch self {
        case .discipline:
            return [Color(hex: "0A84FF"), Color(hex: "5e5ce6")]  // Blue to Purple
        case .calm:
            return [Color(hex: "30D158"), Color(hex: "0A84FF")]  // Green to Blue
        case .courage:
            return [Color(hex: "FF453A"), Color(hex: "FF9F0A")]  // Red to Orange
        case .wisdom:
            return [Color(hex: "5e5ce6"), Color(hex: "FF453A")]  // Purple to Red
        }
    }
}

// MARK: - Affirmation Display View

struct AffirmationDisplayView: View {
    let affirmation: DailyAffirmation
    @State private var glowIntensity: CGFloat = 0.3
    @State private var showInternalizing = false
    @State private var isInternalized = false

    var body: some View {
        VStack(spacing: 15) {
            Spacer()

            // Main affirmation card
            ZStack {
                // Gradient background with pulsing glow
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: affirmation.category.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: affirmation.category.gradient.first!.opacity(glowIntensity),
                        radius: 20
                    )

                // Affirmation text
                Text(affirmation.text)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(20)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            }
            .frame(height: 280)
            .padding(.horizontal, 16)

            // "Internalizing..." indicator
            if showInternalizing {
                HStack(spacing: 8) {
                    if !isInternalized {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "30D158"))
                    }

                    Text(isInternalized ? "Internalized" : "Internalizing...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulsing glow
        withAnimation(
            Animation.easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 0.6
        }

        // Show internalizing after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showInternalizing = true
            }
        }

        // Mark as internalized after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                isInternalized = true
            }

            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }
}

// MARK: - Affirmed Completion View

struct AffirmedView: View {
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Large checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)

            Text("Affirmed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .opacity(checkmarkOpacity)

            Text("Carry this mindset")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .opacity(checkmarkOpacity)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            // Animated entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }

            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }
}

// MARK: - Affirmation Carousel

struct AffirmationCarouselView: View {
    @State private var currentIndex = 0
    @State private var affirmations: [DailyAffirmation] = []

    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: previousAffirmation) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0A84FF"))
                }

                Spacer()

                Text("Affirmation \(currentIndex + 1)/\(affirmations.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))

                Spacer()

                Button(action: nextAffirmation) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Current affirmation
            if !affirmations.isEmpty {
                AffirmationDisplayView(affirmation: affirmations[currentIndex])
            }
        }
        .onAppear {
            loadAffirmations()
        }
    }

    // MARK: - Navigation

    private func previousAffirmation() {
        withAnimation {
            currentIndex = (currentIndex - 1 + affirmations.count) % affirmations.count
        }
    }

    private func nextAffirmation() {
        withAnimation {
            currentIndex = (currentIndex + 1) % affirmations.count
        }
    }

    private func loadAffirmations() {
        affirmations = [
            DailyAffirmation(
                text: "I am disciplined and master of my own actions.",
                category: .discipline
            ),
            DailyAffirmation(
                text: "I am calm and in full control of my reactions.",
                category: .calm
            ),
            DailyAffirmation(
                text: "I have the courage to face any challenge.",
                category: .courage
            ),
            DailyAffirmation(
                text: "I choose wisdom in all my decisions.",
                category: .wisdom
            )
        ]
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("Affirmation Display") {
    AffirmationDisplayView(
        affirmation: DailyAffirmation(
            text: "I am disciplined and master of my own actions.",
            category: .discipline
        )
    )
}

#Preview("Affirmed Complete") {
    AffirmedView()
}

#Preview("Affirmation Carousel") {
    AffirmationCarouselView()
}
