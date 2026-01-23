//
//  TodaysPrioritiesView.swift
//  Stoic Companion
//
//  Daily priorities checklist matching HTML mockup design
//  Features: Interactive checkboxes, completion tracking, haptic feedback
//

import SwiftUI

// MARK: - Priority Item Model

struct PriorityItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var category: PriorityCategory

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: PriorityCategory = .virtue) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
    }
}

enum PriorityCategory: String, Codable {
    case virtue = "Virtue"
    case reflection = "Reflection"
    case action = "Action"

    var color: Color {
        switch self {
        case .virtue: return Color(hex: "30D158")    // Green
        case .reflection: return Color(hex: "0A84FF") // Blue
        case .action: return Color(hex: "FF453A")     // Red
        }
    }
}

// MARK: - Today's Priorities View

struct TodaysPrioritiesView: View {
    @State private var priorities: [PriorityItem] = [
        PriorityItem(title: "Deep Work Block", category: .action),
        PriorityItem(title: "Midday Reflection", category: .reflection),
        PriorityItem(title: "Evening Walk", category: .virtue)
    ]

    @State private var showCompleted = false

    var completionPercentage: Double {
        let completed = priorities.filter { $0.isCompleted }.count
        return priorities.isEmpty ? 0 : Double(completed) / Double(priorities.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Today's Priorities")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("10:09")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Progress indicator
            if !priorities.isEmpty {
                HStack(spacing: 4) {
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    ProgressView(value: completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "30D158")))
                        .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Priority list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($priorities) { $priority in
                        PriorityRow(priority: $priority)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Spacer()

            // All complete state
            if completionPercentage == 1.0 {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "30D158"))

                    Text("All priorities complete!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Text("Focus on virtue")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            loadPriorities()
        }
    }

    // MARK: - Helper Methods

    private func loadPriorities() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "todaysPriorities"),
           let decoded = try? JSONDecoder().decode([PriorityItem].self, from: data) {
            priorities = decoded
        }
    }

    private func savePriorities() {
        if let encoded = try? JSONEncoder().encode(priorities) {
            UserDefaults.standard.set(encoded, forKey: "todaysPriorities")
        }
    }
}

// MARK: - Priority Row Component

struct PriorityRow: View {
    @Binding var priority: PriorityItem
    @State private var showCheckmark = false

    var body: some View {
        Button(action: {
            toggleCompletion()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            priority.isCompleted ? priority.category.color : Color(hex: "8E8E93"),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if priority.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(priority.category.color)
                            .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    }
                }

                // Title
                Text(priority.title)
                    .font(.system(size: 14, weight: priority.isCompleted ? .regular : .medium))
                    .foregroundColor(priority.isCompleted ? Color(hex: "8E8E93") : .white)
                    .strikethrough(priority.isCompleted, color: Color(hex: "8E8E93"))

                Spacer()

                // Category indicator
                if !priority.isCompleted {
                    Circle()
                        .fill(priority.category.color.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1c1c1e"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            priority.isCompleted.toggle()
            showCheckmark = priority.isCompleted
        }

        // Haptic feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(priority.isCompleted ? .success : .click)
        #endif

        // Save to storage
        savePriority()
    }

    private func savePriority() {
        // Trigger parent save
        NotificationCenter.default.post(name: NSNotification.Name("SavePriorities"), object: nil)
    }
}

// MARK: - Plan Complete View

struct PlanCompleteView: View {
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Large checkmark
            ZStack {
                Circle()
                    .fill(Color(hex: "30D158").opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(hex: "30D158"))
            }

            // Title
            Text("Plan Complete.")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("Focus on Virtue")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))

            Spacer()

            // Daily wisdom
            Text("\"The happiness of your life depends upon the quality of your thoughts.\"")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            // Haptic celebration
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }
}

// MARK: - Compact Card Version

struct PrioritiesCard: View {
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "0A84FF"))

            Text("\(completedCount)/\(totalCount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text("Priorities")
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

#Preview("Today's Priorities") {
    TodaysPrioritiesView()
}

#Preview("Plan Complete") {
    PlanCompleteView()
}

#Preview("Priorities Card") {
    PrioritiesCard(completedCount: 2, totalCount: 3)
        .frame(width: 150, height: 150)
        .background(Color.black)
}
