//
//  MementoMoriView.swift
//  StoicCamarade Watch App
//
//  Death countdown to inspire urgency and gratitude - "Remember you will die"
//  Part of the Nano Banana Pro Series aesthetic.
//

import SwiftUI
import Combine

// MARK: - Memento Mori Manager

class MementoMoriManager: ObservableObject {
    static let shared = MementoMoriManager()

    @Published var birthDate: Date?
    @Published var expectedLifespan: Int = 80 // Default to 80 years

    private let birthDateKey = "stoic_birth_date"
    private let lifespanKey = "stoic_expected_lifespan"

    init() {
        loadData()
    }

    private func loadData() {
        if let timestamp = UserDefaults.standard.object(forKey: birthDateKey) as? Double {
            birthDate = Date(timeIntervalSince1970: timestamp)
        }
        expectedLifespan = UserDefaults.standard.integer(forKey: lifespanKey)
        if expectedLifespan == 0 { expectedLifespan = 80 }
    }

    func saveData() {
        if let date = birthDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: birthDateKey)
        }
        UserDefaults.standard.set(expectedLifespan, forKey: lifespanKey)
    }

    var yearsLived: Int {
        guard let birth = birthDate else { return 0 }
        let components = Calendar.current.dateComponents([.year], from: birth, to: Date())
        return components.year ?? 0
    }

    var yearsRemaining: Int {
        max(0, expectedLifespan - yearsLived)
    }

    var daysRemaining: Int {
        guard let birth = birthDate,
              let expectedDeath = Calendar.current.date(byAdding: .year, value: expectedLifespan, to: birth) else {
            return 0
        }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: expectedDeath)
        return max(0, components.day ?? 0)
    }

    var percentageLived: Double {
        guard expectedLifespan > 0 else { return 0 }
        return min(1.0, Double(yearsLived) / Double(expectedLifespan))
    }

    var weeksRemaining: Int {
        daysRemaining / 7
    }

    var formattedTimeRemaining: String {
        let years = yearsRemaining
        let totalDays = daysRemaining
        let remainingDays = totalDays - (years * 365)

        return "\(years)Y \(remainingDays)D"
    }
}

// MARK: - Memento Mori View

struct MementoMoriView: View {
    @ObservedObject private var manager = MementoMoriManager.shared
    @State private var showingSetup = false
    @State private var showingQuote = false
    
    // Animation states
    @State private var animateRing = false
    @State private var animateSkull = false
    @State private var backgroundPulse = 0.0

    var body: some View {
        ZStack {
            // Nano Banana Pro: Animated Deep Gradient Background
            PremiumBackgroundView()
            
            ScrollView {
                VStack(spacing: 16) {
                    if manager.birthDate == nil {
                        setupPrompt
                    } else {
                        mainCountdownDisplay
                        timeDetailsCards
                        actionButtons
                    }
                }
                .padding()
            }
        }
        .navigationTitle("") // Using custom header for premium feel
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSetup) {
            setupSheet
        }
        .sheet(isPresented: $showingQuote) {
            quoteSheet
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateRing = true
                animateSkull = true
            }
        }
    }

    // MARK: - Components

    private var mainCountdownDisplay: some View {
        VStack(spacing: 8) {
            // View Title
            Text("MEMENTO MORI")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                .tracking(2)
            
            // Life progress ring
            ZStack {
                // Background track with subtle glow
                Circle()
                    .stroke(Color.white.opacity(0.03), lineWidth: 10)
                    .frame(width: 120, height: 120)

                // The Progress Ring
                Circle()
                    .trim(from: 0, to: manager.percentageLived)
                    .stroke(
                        LinearGradient(
                            colors: [PremiumAssets.Colors.vibrantOrange, .red, .black.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.5), radius: animateRing ? 15 : 5)

                // Skull icon & main stat
                VStack(spacing: 4) {
                    Image(systemName: "skull.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .scaleEffect(animateSkull ? 1.05 : 1.0)
                        .shadow(color: .white.opacity(0.2), radius: 5)
                    
                    Text("\(manager.yearsRemaining)")
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("YEARS LEFT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.gray)
                        .tracking(1)
                }
            }
            .frame(width: 150, height: 150)
            .padding(.vertical, 8)
        }
    }

    private var timeDetailsCards: some View {
        Button(action: { 
            WKInterfaceDevice.current().play(.click)
            showingQuote = true 
        }) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DetailCard(value: "\(manager.daysRemaining)", label: "Days", color: .white)
                    DetailCard(value: "\(manager.weeksRemaining)", label: "Weeks", color: PremiumAssets.Colors.vibrantOrange)
                }
                
                // Urgency Quote Preview
                HStack {
                    Image(systemName: "hourglass")
                        .font(.system(size: 10))
                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                    Text("Time is the only thing we cannot recover.")
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .foregroundColor(.gray)
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button(action: { 
                WKInterfaceDevice.current().play(.click)
                showingSetup = true 
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Adjust Lifespan")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Set to \(manager.expectedLifespan) years")
                .font(.system(size: 8))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.top, 8)
    }

    // MARK: - Setup Prompt

    private var setupPrompt: some View {
        VStack(spacing: 16) {
            PremiumAssets.VirtueIcon(virtue: .wisdom, size: 60)
            
            Text("SET YOUR HORIZON")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .tracking(1)

            Text("Stoicism teaches us to live with death in view, not to mourn, but to thrive.")
                .font(.system(size: 10, design: .serif))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { 
                WKInterfaceDevice.current().play(.click)
                showingSetup = true 
            }) {
                Text("BEGIN")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(PremiumAssets.Colors.vibrantOrange)
                    .cornerRadius(20)
                    .shadow(color: PremiumAssets.Colors.vibrantOrange.opacity(0.3), radius: 10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 20)
    }

    // MARK: - Sheets

    private var setupSheet: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("BIRTH DATE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { manager.birthDate ?? Date() },
                        set: { manager.birthDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 80)

                Divider().background(Color.white.opacity(0.1))

                VStack(spacing: 4) {
                    HStack {
                        Text("EXPECTED AGE")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Text("\(manager.expectedLifespan)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(manager.expectedLifespan) },
                            set: { manager.expectedLifespan = Int($0) }
                        ),
                        in: 60...110,
                        step: 1
                    )
                    .tint(PremiumAssets.Colors.vibrantOrange)
                }

                Button(action: {
                    WKInterfaceDevice.current().play(.success)
                    manager.saveData()
                    showingSetup = false
                }) {
                    Text("SAVE HORIZON")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PremiumAssets.Colors.vibrantOrange)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }

    private var quoteSheet: some View {
        ZStack {
            PremiumAssets.Colors.deepBlack.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                Text("It is not that we have a short time to live, but that we waste a lot of it.")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("— SENECA")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                    .tracking(1)

                Button(action: { showingQuote = false }) {
                    Text("LIVE NOW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 10)
            }
            .padding()
        }
    }
}

// MARK: - Premium UI Components

struct PremiumBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            PremiumAssets.Colors.deepBlack.ignoresSafeArea()
            
            // Subtle, slow-moving gradient blobs
            Circle()
                .fill(PremiumAssets.Colors.vibrantOrange.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: animate ? 50 : -50, y: animate ? -30 : 30)
                .blur(radius: 50)
            
            Circle()
                .fill(Color.red.opacity(0.05))
                .frame(width: 150, height: 150)
                .offset(x: animate ? -40 : 40, y: animate ? 40 : -40)
                .blur(radius: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct DetailCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.gray.opacity(0.8))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            PremiumAssets.GlassBackdrop(cornerRadius: 16)
        )
    }
}

#Preview {
    MementoMoriView()
}
