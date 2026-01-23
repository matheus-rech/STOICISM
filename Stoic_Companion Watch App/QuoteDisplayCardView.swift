//
//  QuoteDisplayCardView.swift
//  Stoic Companion
//
//  Enhanced quote display matching HTML mockup design
//  Features: Multiple display styles, navigation, favorites, sharing
//

import SwiftUI

// MARK: - Quote Display Styles

enum QuoteDisplayStyle {
    case card        // Card with background
    case minimal     // Text only
    case navigation  // With quote counter (1/99)
}

// MARK: - Quote Display Card

struct QuoteDisplayCardView: View {
    let quote: StoicQuote
    let style: QuoteDisplayStyle
    let currentIndex: Int?
    let totalQuotes: Int?

    @State private var isFavorite = false
    @State private var showActions = false

    init(
        quote: StoicQuote,
        style: QuoteDisplayStyle = .card,
        currentIndex: Int? = nil,
        totalQuotes: Int? = nil
    ) {
        self.quote = quote
        self.style = style
        self.currentIndex = currentIndex
        self.totalQuotes = totalQuotes
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            if let current = currentIndex, let total = totalQuotes {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "0A84FF"))
                    }

                    Spacer()

                    Text("Quote of the Day \(current)/\(total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))

                    Spacer()

                    Button(action: { showActions.toggle() }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "0A84FF"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Main quote display
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 20)

                    // Quote text
                    Text(quote.text)
                        .font(.system(size: style == .minimal ? 16 : 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)

                    // Attribution
                    HStack(spacing: 4) {
                        Text("—")
                            .foregroundColor(Color(hex: "8E8E93"))

                        Text(quote.author)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }

                    // Book reference
                    if !quote.book.isEmpty {
                        Text(quote.book)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .italic()
                    }

                    Spacer(minLength: 20)
                }
            }

            // Action buttons
            if style == .card {
                HStack(spacing: 20) {
                    Button(action: toggleFavorite) {
                        VStack(spacing: 4) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(isFavorite ? .red : Color(hex: "8E8E93"))

                            Text(isFavorite ? "Saved" : "Save")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: shareQuote) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "8E8E93"))

                            Text("Share")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "0A84FF"))

                            Text("New")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(isPresented: $showActions) {
            QuoteActionsSheet(quote: quote)
        }
        .onAppear {
            loadFavoriteStatus()
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.3)) {
            isFavorite.toggle()
        }

        #if os(watchOS)
        WKInterfaceDevice.current().play(isFavorite ? .success : .click)
        #endif

        // Save to PersistenceManager
        if isFavorite {
            PersistenceManager.shared.addFavorite(quoteId: quote.id)
        } else {
            PersistenceManager.shared.removeFavorite(quoteId: quote.id)
        }
    }

    private func shareQuote() {
        // Share sheet implementation
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    private func loadFavoriteStatus() {
        isFavorite = PersistenceManager.shared.isFavorite(quoteId: quote.id)
    }
}

// MARK: - Loading State

struct QuoteLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated spinner
            ZStack {
                Circle()
                    .stroke(Color(hex: "8E8E93").opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color(hex: "0A84FF"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
            }

            Text("Loading wisdom...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Quote Actions Sheet

struct QuoteActionsSheet: View {
    let quote: StoicQuote
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Quote Actions")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top)

            Button(action: {
                // Mark as helpful
                dismiss()
            }) {
                HStack {
                    Image(systemName: "hand.thumbsup")
                    Text("Mark as Helpful")
                    Spacer()
                }
                .padding()
                .background(Color(hex: "1c1c1e"))
                .cornerRadius(12)
            }

            Button(action: {
                // Share
                dismiss()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Quote")
                    Spacer()
                }
                .padding()
                .background(Color(hex: "1c1c1e"))
                .cornerRadius(12)
            }

            Button(action: {
                // View author
                dismiss()
            }) {
                HStack {
                    Image(systemName: "person.circle")
                    Text("About \(quote.author)")
                    Spacer()
                }
                .padding()
                .background(Color(hex: "1c1c1e"))
                .cornerRadius(12)
            }

            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Minimal Quote Display

struct MinimalQuoteView: View {
    let quote: StoicQuote

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(quote.text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)

            Text("— \(quote.author)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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

#Preview("Quote Card") {
    QuoteDisplayCardView(
        quote: StoicQuote(
            id: "1",
            text: "The obstacle is the way.",
            author: "Marcus Aurelius",
            book: "Meditations, Book V",
            contexts: ["action"],
            heartRateContext: nil,
            timeOfDay: nil,
            activityContext: nil
        ),
        style: .card
    )
}

#Preview("Quote with Navigation") {
    QuoteDisplayCardView(
        quote: StoicQuote(
            id: "1",
            text: "Waste no more time arguing what a good man should be. Be one.",
            author: "Marcus Aurelius",
            book: "Meditations",
            contexts: ["action"],
            heartRateContext: nil,
            timeOfDay: nil,
            activityContext: nil
        ),
        style: .navigation,
        currentIndex: 1,
        totalQuotes: 99
    )
}

#Preview("Loading State") {
    QuoteLoadingView()
}

#Preview("Minimal Quote") {
    MinimalQuoteView(
        quote: StoicQuote(
            id: "1",
            text: "The happiness of your life depends upon the quality of your thoughts.",
            author: "Marcus Aurelius",
            book: "Meditations",
            contexts: ["wisdom"],
            heartRateContext: nil,
            timeOfDay: nil,
            activityContext: nil
        )
    )
}
