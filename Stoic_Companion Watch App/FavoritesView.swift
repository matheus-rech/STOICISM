//
//  FavoritesView.swift
//  StoicCompanion Watch App
//
//  Display and manage favorite stoic quotes
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var persistence = PersistenceManager.shared
    @StateObject private var quoteManager = QuoteManager()
    @State private var selectedQuote: StoicQuote?
    @State private var showingQuoteDetail = false

    var body: some View {
        Group {
            if persistence.favorites.isEmpty {
                emptyStateView
            } else {
                favoritesList
            }
        }
        .navigationTitle("Favorites")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Favorites Yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("Tap the heart on any quote to save it here")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Favorites List

    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(getFavoriteQuotes(), id: \.id) { quote in
                    FavoriteQuoteCard(
                        quote: quote,
                        onTap: {
                            selectedQuote = quote
                            showingQuoteDetail = true
                        },
                        onRemove: {
                            withAnimation {
                                persistence.removeFavorite(quote.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingQuoteDetail) {
            if let quote = selectedQuote {
                QuoteDetailView(quote: quote)
            }
        }
    }

    // MARK: - Helpers

    private func getFavoriteQuotes() -> [StoicQuote] {
        return quoteManager.getQuotes(byIds: Array(persistence.favorites))
    }
}

// MARK: - Favorite Quote Card

struct FavoriteQuoteCard: View {
    let quote: StoicQuote
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Quote preview (truncated)
                Text(quote.text)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(3)

                HStack {
                    // Author
                    Text("— \(quote.author)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)

                    Spacer()

                    // Remove button
                    Button(action: onRemove) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.4))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quote Detail View

struct QuoteDetailView: View {
    let quote: StoicQuote
    @ObservedObject private var persistence = PersistenceManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Favorite button
                HStack {
                    Spacer()
                    Button(action: {
                        persistence.toggleFavorite(quote.id)
                    }) {
                        Image(systemName: persistence.isFavorite(quote.id) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(persistence.isFavorite(quote.id) ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Quote text
                Text(quote.text)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Divider
                Divider()
                    .background(Color.gray.opacity(0.3))

                // Author and book
                VStack(spacing: 4) {
                    Text("— \(quote.author)")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundColor(.orange)

                    Text(quote.book ?? "Stoic Source")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }

                // Context tags
                if !quote.contexts.isEmpty {
                    WrappingHStack(quote.contexts.prefix(4).map { $0 }) { context in
                        Text(context)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.3))
                            )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quote")
    }
}

// MARK: - Wrapping HStack Helper

struct WrappingHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        FavoritesView()
    }
}
