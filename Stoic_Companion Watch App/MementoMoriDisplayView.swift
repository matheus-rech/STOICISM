//
//  MementoMoriDisplayView.swift
//  Stoic Companion
//
//  Enhanced Memento Mori display matching HTML mockup design
//  Features: Life expectancy countdown, animated skull, real-time updates
//

import SwiftUI

// MARK: - Memento Mori Display Component

struct MementoMoriDisplayView: View {
    @State private var currentAge: Int = 0
    @State private var yearsRemaining: Int = 41
    @State private var daysRemaining: Int = 210
    @State private var skullScale: CGFloat = 1.0
    @State private var timer: Timer?

    // User configuration (could be loaded from UserDefaults)
    private let birthDate: Date
    private let lifeExpectancy: Int

    init(birthDate: Date = Date(), lifeExpectancy: Int = 81) {
        self.birthDate = birthDate
        self.lifeExpectancy = lifeExpectancy
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Skull icon with subtle animation
            Text("💀")
                .font(.system(size: 48))
                .opacity(0.8)
                .scaleEffect(skullScale)
                .padding(.bottom, 10)

            // Title
            Text("Memento Mori")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 20)

            // Life expectancy label
            Text("Estimated Time")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8E8E93"))
                .padding(.bottom, 4)

            // Main countdown display
            HStack(spacing: 0) {
                Text("\(yearsRemaining)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(" Years, ")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))

                Text("\(daysRemaining)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(" Days")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.bottom, 30)

            // Subtle reminder text
            Text("Use your time wisely")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
                .italic()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            calculateTimeRemaining()
            startSkullAnimation()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Helper Methods

    private func calculateTimeRemaining() {
        let now = Date()
        let calendar = Calendar.current

        // Calculate current age
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        currentAge = ageComponents.year ?? 0

        // Calculate years remaining
        yearsRemaining = max(0, lifeExpectancy - currentAge)

        // Calculate days remaining until next birthday
        guard let nextBirthday = calendar.nextDate(
            after: now,
            matching: calendar.dateComponents([.month, .day], from: birthDate),
            matchingPolicy: .nextTime
        ) else { return }

        let daysComponents = calendar.dateComponents([.day], from: now, to: nextBirthday)
        daysRemaining = daysComponents.day ?? 0
    }

    private func startSkullAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
        ) {
            skullScale = 1.05
        }
    }

    private func startTimer() {
        // Update daily at midnight
        timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            calculateTimeRemaining()
        }
    }
}

// MARK: - Enhanced Version with Settings

struct MementoMoriEnhancedView: View {
    @State private var showSettings = false
    @State private var yearsRemaining: Int = 41
    @State private var daysRemaining: Int = 210

    var body: some View {
        VStack {
            // Header with settings button
            HStack {
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
                Spacer()
                Text("10:09")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Main display
            MementoMoriDisplayView()
        }
        .sheet(isPresented: $showSettings) {
            MementoMoriSettingsView()
        }
    }
}

// MARK: - Settings View

struct MementoMoriSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var birthDate = Date()
    @State private var lifeExpectancy = 81

    var body: some View {
        VStack(spacing: 20) {
            Text("Memento Mori Settings")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top)

            VStack(alignment: .leading, spacing: 12) {
                Text("Birth Date")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Life Expectancy")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Stepper("\(lifeExpectancy) years", value: $lifeExpectancy, in: 60...120)
                    .font(.system(size: 14))
            }

            Button("Save") {
                // Save to UserDefaults
                UserDefaults.standard.set(birthDate, forKey: "mementoMori_birthDate")
                UserDefaults.standard.set(lifeExpectancy, forKey: "mementoMori_lifeExpectancy")
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Spacer()
        }
        .padding()
        .background(Color(hex: "1c1c1e"))
    }
}

// MARK: - Compact Card Version (for ToolsGridView)

struct MementoMoriCard: View {
    @State private var yearsRemaining: Int = 41

    var body: some View {
        VStack(spacing: 8) {
            Text("💀")
                .font(.system(size: 32))
                .opacity(0.8)

            Text("\(yearsRemaining) Years")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()

            Text("Memento Mori")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "1c1c1e"))
        .cornerRadius(24)
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

#Preview("Memento Mori Display") {
    MementoMoriDisplayView()
}

#Preview("Enhanced with Header") {
    MementoMoriEnhancedView()
}

#Preview("Card Version") {
    MementoMoriCard()
        .frame(width: 150, height: 150)
        .background(Color.black)
}
