//
//  FavoritesMenuView.swift
//  Stoic Companion
//
//  Favorites menu grid matching HTML mockup design
//  Features: Quick access grid with icons, customizable favorites
//

import SwiftUI

// MARK: - Favorite Action Model

struct FavoriteAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - Favorites Menu View

struct FavoritesMenuView: View {
    @State private var favoriteActions: [FavoriteAction] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Favorites")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("10:09")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Favorites grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(getFavoriteActions()) { action in
                    FavoriteActionButton(action: action)
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // MARK: - Helper Methods

    private func getFavoriteActions() -> [FavoriteAction] {
        return [
            FavoriteAction(
                id: "new_quote",
                title: "New Quote",
                icon: "cloud",
                color: Color(hex: "0A84FF")
            ) {},
            FavoriteAction(
                id: "journal",
                title: "Journal",
                icon: "pencil",
                color: Color(hex: "FF9F0A")
            ) {},
            FavoriteAction(
                id: "evening",
                title: "Evening Review",
                icon: "moon",
                color: Color(hex: "5e5ce6")
            ) {},
            FavoriteAction(
                id: "breathing",
                title: "Breathing",
                icon: "lungs.fill",
                color: Color(hex: "30D158")
            ) {}
        ]
    }
}

// MARK: - Favorite Action Button

struct FavoriteActionButton: View {
    let action: FavoriteAction
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }

            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #endif

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action.action()
            }
        }) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: action.icon)
                        .font(.system(size: 24))
                        .foregroundColor(action.color)
                }

                // Label
                Text(action.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1c1c1e"))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Favorites Card

struct FavoritesCard: View {
    let icons: [String]

    init(icons: [String] = ["cloud", "heart", "pencil", "moon"]) {
        self.icons = icons
    }

    var body: some View {
        VStack(spacing: 8) {
            // Grid of tiny icons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(icons.prefix(4).enumerated()), id: \.offset) { index, icon in
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 12)

            Text("Favorites")
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

#Preview("Favorites Menu") {
    FavoritesMenuView()
}

#Preview("Favorites Card") {
    FavoritesCard()
        .frame(width: 150, height: 150)
        .background(Color.black)
}
