//
//  BackendAPIService.swift
//  StoicCompanion Watch App
//
//  Backend API integration for user profiles, philosopher matching, and data sync
//

import Foundation

// MARK: - Backend API Service

/// Service for backend API calls (philosopher matching, user profiles, etc.)
/// Separate from RAGService which handles quote retrieval
class BackendAPIService {

    // MARK: - Configuration

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = Config.ragAPIEndpoint) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Models

    struct OnboardingAnswer: Codable {
        let question_id: String
        let answer: String
    }

    struct MatchRequest: Codable {
        let user_id: String
        let answers: [OnboardingAnswer]
    }

    struct MatchResponse: Codable {
        let philosopher_id: String
        let philosopher_name: String
        let match_reason: String
        let confidence: Double
    }

    struct Philosopher: Codable, Identifiable {
        let id: String
        let name: String
        let era: String
        let biography: String
        let core_themes: [String]
        let teaching_style: String
    }

    struct PhilosophersResponse: Codable {
        let philosophers: [Philosopher]
    }

    struct UserProfileResponse: Codable {
        let user_id: String
        let matched_philosopher_id: String?
        let onboarding_answers: [OnboardingAnswer]?
        let unlocked_philosophers: [String]?
        let created_at: String?
        let updated_at: String?
    }

    // MARK: - Philosopher Matching

    /// Match user with a philosopher based on onboarding answers
    /// Uses AI to analyze answers and provide personalized match reason
    func matchPhilosopher(userId: String, profile: UserProfile) async throws -> MatchResponse {
        guard let url = URL(string: "\(baseURL)/match") else {
            throw BackendAPIError.invalidURL
        }

        // Convert UserProfile to onboarding answers
        let answers = convertProfileToAnswers(profile)

        let requestBody = MatchRequest(
            user_id: userId,
            answers: answers
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        if Config.debugMode {
            print("🔵 Backend: Matching philosopher for user \(userId)")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw BackendAPIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let matchResponse = try JSONDecoder().decode(MatchResponse.self, from: data)

        if Config.debugMode {
            print("🟢 Backend: Matched with \(matchResponse.philosopher_name) (confidence: \(matchResponse.confidence))")
        }

        return matchResponse
    }

    // MARK: - Philosopher List

    /// Fetch list of all available philosophers
    func fetchPhilosophers() async throws -> [Philosopher] {
        guard let url = URL(string: "\(baseURL)/philosophers") else {
            throw BackendAPIError.invalidURL
        }

        if Config.debugMode {
            print("🔵 Backend: Fetching philosopher list")
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BackendAPIError.invalidResponse
        }

        let philosophersResponse = try JSONDecoder().decode(PhilosophersResponse.self, from: data)

        if Config.debugMode {
            print("🟢 Backend: Fetched \(philosophersResponse.philosophers.count) philosophers")
        }

        return philosophersResponse.philosophers
    }

    // MARK: - User Profile

    /// Fetch user profile from backend
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/profile") else {
            throw BackendAPIError.invalidURL
        }

        if Config.debugMode {
            print("🔵 Backend: Fetching user profile for \(userId)")
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw BackendAPIError.userNotFound
            }
            throw BackendAPIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let profileResponse = try JSONDecoder().decode(UserProfileResponse.self, from: data)

        if Config.debugMode {
            print("🟢 Backend: Fetched profile for \(userId)")
        }

        return profileResponse
    }

    // MARK: - Helper Methods

    /// Convert UserProfile to OnboardingAnswer array for API
    private func convertProfileToAnswers(_ profile: UserProfile) -> [OnboardingAnswer] {
        var answers: [OnboardingAnswer] = []

        // Profession
        answers.append(OnboardingAnswer(
            question_id: "profession",
            answer: profile.profession.displayName
        ))

        // Current focus/challenge
        answers.append(OnboardingAnswer(
            question_id: "challenge",
            answer: profile.currentFocus.displayName
        ))

        // Life context
        if !profile.lifeContext.isEmpty {
            let contexts = profile.lifeContext.map { $0.displayName }.joined(separator: ", ")
            answers.append(OnboardingAnswer(
                question_id: "life_context",
                answer: contexts
            ))
        }

        // Stoic goals
        if !profile.stoicGoals.isEmpty {
            let goals = profile.stoicGoals.map { $0.displayName }.joined(separator: ", ")
            answers.append(OnboardingAnswer(
                question_id: "goals",
                answer: goals
            ))
        }

        // Approach/teaching style preference
        answers.append(OnboardingAnswer(
            question_id: "approach",
            answer: describeTeachingStylePreference(profile)
        ))

        return answers
    }

    /// Generate a description of the user's preferred teaching style based on their profile
    private func describeTeachingStylePreference(_ profile: UserProfile) -> String {
        switch profile.profession {
        case .healthcare, .military, .publicService:
            return "practical, duty-focused wisdom for high-pressure roles"
        case .business, .legal:
            return "leadership-oriented, decision-making guidance"
        case .creative, .education:
            return "philosophical depth with creative perspective"
        case .student:
            return "foundational teachings with modern relevance"
        case .parent:
            return "compassionate wisdom for daily challenges"
        default:
            return "balanced, accessible stoic philosophy"
        }
    }
}

// MARK: - Backend API Errors

enum BackendAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case userNotFound
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend API URL"
        case .invalidResponse:
            return "Invalid response from backend"
        case .requestFailed(let code):
            return "Request failed with status code \(code)"
        case .userNotFound:
            return "User profile not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
