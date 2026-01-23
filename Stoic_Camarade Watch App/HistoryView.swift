//
//  HistoryView.swift
//  StoicCamarade Watch App
//
//  Display quote history with effectiveness tracking and statistics
//  Part of the Nano Banana Pro Series aesthetic.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var persistence = PersistenceManager.shared
    @StateObject private var quoteManager = QuoteManager()
    @State private var showingStats = false

    var body: some View {
        ZStack {
            // Nano Banana Pro: Animated Deep Background
            PremiumBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics summary card
                    statisticsSummaryCard
                        .padding(.top, 10)

                    if persistence.history.isEmpty {
                        emptyStateView
                    } else {
                        historyContent
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.2))

            Text("NO HISTORY YET")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.gray)

            Text("Your journey into wisdom begins when you view your first quote.")
                .font(.system(size: 9))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - History Content

    private var historyContent: some View {
        VStack(spacing: 16) {
            // Today's quotes
            if !persistence.getHistoryForToday().isEmpty {
                sectionHeader("TODAY")
                ForEach(persistence.getHistoryForToday()) { entry in
                    HistoryEntryCard(entry: entry, quoteManager: quoteManager)
                }
            }

            // Recent quotes
            let recent = persistence.getRecentHistory(limit: 15).filter { !isFromToday($0) }
            if !recent.isEmpty {
                sectionHeader("RECENT")
                ForEach(recent) { entry in
                    HistoryEntryCard(entry: entry, quoteManager: quoteManager)
                }
            }
        }
    }

    // MARK: - Statistics Summary Card

    private var statisticsSummaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "tent.2.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                Text("THE JOURNEY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(2)
                Spacer()
            }

            HStack(spacing: 10) {
                StatBox(
                    value: "\(persistence.statistics.totalQuotesViewed)",
                    label: "QUOTES",
                    icon: "quote.bubble",
                    color: PremiumAssets.Colors.vibrantOrange
                )

                StatBox(
                    value: "\(persistence.statistics.currentStreak)",
                    label: "STREAK",
                    icon: "flame.fill",
                    color: .red
                )

                StatBox(
                    value: "\(persistence.statistics.helpfulCount)",
                    label: "HELPFUL",
                    icon: "hand.thumbsup.fill",
                    color: PremiumAssets.Colors.successGreen
                )
            }
        }
        .padding(14)
        .background(
            PremiumAssets.GlassBackdrop(cornerRadius: 20, opacity: 0.08)
        )
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.gray)
                .tracking(2)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func isFromToday(_ entry: QuoteHistoryEntry) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(entry.timestamp)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 3)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(label.uppercased())
                .font(.system(size: 6, weight: .black))
                .foregroundColor(.gray.opacity(0.8))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            PremiumAssets.GlassBackdrop(cornerRadius: 14, opacity: 0.1)
        )
    }
}

// MARK: - History EntryCard

struct HistoryEntryCard: View {
    let entry: QuoteHistoryEntry
    @ObservedObject var quoteManager: QuoteManager
    @ObservedObject private var persistence = PersistenceManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote preview
            if let quote = quoteManager.getQuote(byId: entry.quoteId) {
                Text(quote.text)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(3)
                    .lineSpacing(2)

                HStack(alignment: .bottom) {
                    // Author
                    Text("— \(quote.author.uppercased())")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                        .tracking(1)

                    Spacer()

                    // Time
                    Text(formatTime(entry.timestamp).uppercased())
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.gray.opacity(0.6))
                        .tracking(0.5)
                }
            } else {
                Text("Wisdom from the archives")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(.gray)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // Context and feedback
            HStack(spacing: 8) {
                // Context badge
                PremiumContextBadge(context: entry.context)

                // Heart rate if available
                if let hr = entry.heartRate {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                        Text("\(Int(hr))")
                            .font(.system(size: 8, weight: .black))
                    }
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
                }

                Spacer()

                // Feedback buttons
                if entry.helpful == nil {
                    HStack(spacing: 14) {
                        FeedbackButton(
                            icon: "hand.thumbsup.fill",
                            action: { markHelpful(true) }
                        )
                        FeedbackButton(
                            icon: "hand.thumbsdown.fill",
                            action: { markHelpful(false) }
                        )
                    }
                } else {
                    Image(systemName: entry.helpful! ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(entry.helpful! ? PremiumAssets.Colors.successGreen : .gray)
                        .padding(6)
                        .background(Circle().fill(entry.helpful! ? PremiumAssets.Colors.successGreen.opacity(0.15) : Color.white.opacity(0.1)))
                }
            }
        }
        .padding(14)
        .background(
            PremiumAssets.GlassBackdrop(cornerRadius: 20)
        )
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func markHelpful(_ helpful: Bool) {
        persistence.markQuoteHelpful(entryId: entry.id, helpful: helpful)
    }
}

// MARK: - Premium Context Badge

struct PremiumContextBadge: View {
    let context: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForContext)
                .font(.system(size: 8, weight: .bold))
            Text(context.uppercased())
                .font(.system(size: 7, weight: .black))
                .tracking(0.5)
        }
        .foregroundColor(colorForContext)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(colorForContext.opacity(0.2))
        )
    }

    private var iconForContext: String {
        switch context.lowercased() {
        case "morning": return "sunrise.fill"
        case "evening", "night": return "moon.fill"
        case "stress", "anxiety": return "bolt.fill"
        case "active": return "figure.walk"
        default: return "circle.fill"
        }
    }

    private var colorForContext: Color {
        switch context.lowercased() {
        case "morning": return .yellow
        case "evening", "night": return .purple
        case "stress", "anxiety": return .red
        case "active": return PremiumAssets.Colors.successGreen
        default: return PremiumAssets.Colors.vibrantOrange
        }
    }
}

// MARK: - Feedback Button

struct FeedbackButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HistoryView()
    }
}
