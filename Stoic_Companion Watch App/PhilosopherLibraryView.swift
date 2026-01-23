//
//  PhilosopherLibraryView.swift
//  StoicCompanion Watch App
//
//  Philosopher library with detailed profiles from backend API
//

import SwiftUI
import Combine

struct PhilosopherLibraryView: View {
    @StateObject private var viewModel = PhilosopherLibraryViewModel()

    var body: some View {
        ZStack {
            PremiumBackgroundView()

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(PremiumAssets.Colors.vibrantOrange)
                    Text("Loading philosophers...")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button(action: { Task { await viewModel.loadPhilosophers() } }) {
                        Text("Retry")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 4) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 30))
                                .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                            Text("PHILOSOPHER LIBRARY")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                                .tracking(2)

                            Text("Meet the ancient Stoics")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)

                        // Philosopher List
                        ForEach(viewModel.philosophers) { philosopher in
                            NavigationLink(destination: PhilosopherDetailView(philosopher: philosopher)) {
                                PhilosopherCard(philosopher: philosopher)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Philosophers")
        .task {
            await viewModel.loadPhilosophers()
        }
    }
}

// MARK: - Philosopher Card

struct PhilosopherCard: View {
    let philosopher: BackendAPIService.Philosopher

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon
                Image(systemName: "person.bust.fill")
                    .font(.system(size: 20))
                    .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.orange.opacity(0.1)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(philosopher.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    Text(philosopher.era)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            // Core themes
            if !philosopher.core_themes.isEmpty {
                HStack(spacing: 4) {
                    ForEach(philosopher.core_themes.prefix(3), id: \.self) { theme in
                        Text(theme)
                            .font(.system(size: 8))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(12)
        .background(PremiumAssets.GlassBackdrop(cornerRadius: 16, opacity: 0.08))
    }
}

// MARK: - Philosopher Detail View

struct PhilosopherDetailView: View {
    let philosopher: BackendAPIService.Philosopher

    var body: some View {
        ZStack {
            PremiumBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.bust.fill")
                            .font(.system(size: 50))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)
                            .padding(24)
                            .background(Circle().fill(Color.orange.opacity(0.1)))

                        Text(philosopher.name)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(.white)

                        Text(philosopher.era)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    // Biography
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Biography")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                        Text(philosopher.biography)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(PremiumAssets.GlassBackdrop(cornerRadius: 12, opacity: 0.08))

                    // Teaching Style
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teaching Style")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                        Text(philosopher.teaching_style)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(PremiumAssets.GlassBackdrop(cornerRadius: 12, opacity: 0.08))

                    // Core Themes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Core Themes")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PremiumAssets.Colors.vibrantOrange)

                        FlowLayout(spacing: 6) {
                            ForEach(philosopher.core_themes, id: \.self) { theme in
                                Text(theme)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(12)
                    .background(PremiumAssets.GlassBackdrop(cornerRadius: 12, opacity: 0.08))
                }
                .padding()
            }
        }
        .navigationTitle(philosopher.name)
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - View Model

class PhilosopherLibraryViewModel: ObservableObject {
    @Published var philosophers: [BackendAPIService.Philosopher] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let backendAPI = BackendAPIService()

    func loadPhilosophers() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetchedPhilosophers = try await backendAPI.fetchPhilosophers()

            await MainActor.run {
                self.philosophers = fetchedPhilosophers
                self.isLoading = false
            }

            if Config.debugMode {
                print("✅ Loaded \(fetchedPhilosophers.count) philosophers")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load philosophers"
                self.isLoading = false
            }

            if Config.debugMode {
                print("❌ Failed to load philosophers: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Premium Background View
// Note: PremiumBackgroundView is defined in ToolsGridView.swift
