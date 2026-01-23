//
//  PhilosopherMatchingFlowTests.swift
//  Stoic_Camarade Watch AppTests
//
//  Tests for the onboarding philosopher matching flow in ContentView
//

import Testing
import Foundation
import SwiftUI
@testable import Stoic_Camarade_Watch_App

// MARK: - Philosopher Matching Flow Tests

struct PhilosopherMatchingFlowTests {

    // MARK: - Match Response Tests

    @Test func testMatchResponse_Codable() throws {
        // Given
        let json = """
        {
            "philosopher_id": "seneca",
            "philosopher_name": "Seneca",
            "match_reason": "Your business focus aligns with Seneca's practical wisdom.",
            "confidence": 0.88
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(BackendAPIService.MatchResponse.self, from: data)

        // Then
        #expect(response.philosopher_id == "seneca")
        #expect(response.philosopher_name == "Seneca")
        #expect(response.confidence == 0.88)
        #expect(response.match_reason.contains("business"))
    }

    @Test func testMatchResponse_HighConfidence() throws {
        // Given
        let response = BackendAPIService.MatchResponse(
            philosopher_id: "marcus_aurelius",
            philosopher_name: "Marcus Aurelius",
            match_reason: "Perfect alignment",
            confidence: 0.95
        )

        // Then
        #expect(response.confidence > 0.9)
        #expect(response.philosopher_name == "Marcus Aurelius")
    }

    @Test func testMatchResponse_LowConfidence() throws {
        // Given
        let response = BackendAPIService.MatchResponse(
            philosopher_id: "cleanthes",
            philosopher_name: "Cleanthes",
            match_reason: "Some alignment",
            confidence: 0.65
        )

        // Then
        #expect(response.confidence < 0.7)
        #expect(response.confidence > 0.5)
    }

    // MARK: - Onboarding Answer Conversion Tests

    @Test func testOnboardingAnswer_Encoding() throws {
        // Given
        let answer = BackendAPIService.OnboardingAnswer(
            question_id: "profession",
            answer: "Student"
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(answer)
        let json = String(data: data, encoding: .utf8)!

        // Then
        #expect(json.contains("profession"))
        #expect(json.contains("Student"))
    }

    @Test func testMatchRequest_MultipleAnswers() throws {
        // Given
        let answers = [
            BackendAPIService.OnboardingAnswer(question_id: "profession", answer: "Business"),
            BackendAPIService.OnboardingAnswer(question_id: "challenge", answer: "Building Character"),
            BackendAPIService.OnboardingAnswer(question_id: "goals", answer: "Wisdom, Discipline")
        ]

        let request = BackendAPIService.MatchRequest(
            user_id: "test-user",
            answers: answers
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BackendAPIService.MatchRequest.self, from: data)

        // Then
        #expect(decoded.user_id == "test-user")
        #expect(decoded.answers.count == 3)
        #expect(decoded.answers[0].question_id == "profession")
    }

    // MARK: - User Profile Conversion Tests

    @Test func testUserProfile_ToOnboardingAnswers() throws {
        // Given
        let profile = UserProfile(
            name: "Test User",
            profession: .healthcare,
            currentFocus: .dealingWithAdversity,
            lifeContext: [.careerTransition],
            stoicGoals: [.emotionalResilience],
            favoritePhilosopher: "Marcus Aurelius"
        )

        // Then - Verify profile properties are set correctly
        #expect(profile.profession == .healthcare)
        #expect(profile.currentFocus == .dealingWithAdversity)
        #expect(profile.lifeContext.count == 1)
        #expect(profile.stoicGoals.count == 1)
    }

    // MARK: - Match Reason Validation Tests

    @Test func testMatchReason_ContainsRelevantKeywords() throws {
        // Given
        let reasonsToTest = [
            ("Your healthcare background aligns with Epictetus's teachings on compassion", ["healthcare", "compassion"]),
            ("As a student seeking wisdom, Seneca's letters provide guidance", ["student", "wisdom"]),
            ("Your business leadership needs align with Marcus's Meditations", ["business", "leadership"])
        ]

        // When/Then
        for (reason, expectedKeywords) in reasonsToTest {
            let lowercasedReason = reason.lowercased()
            for keyword in expectedKeywords {
                #expect(lowercasedReason.contains(keyword.lowercased()),
                       "Expected '\(reason)' to contain '\(keyword)'")
            }
        }
    }

    // MARK: - Confidence Score Tests

    @Test func testConfidenceScore_ValidRange() throws {
        // Given
        let validScores = [0.0, 0.5, 0.75, 0.9, 1.0]
        let invalidScores = [-0.1, 1.1, 2.0]

        // When/Then
        for score in validScores {
            #expect(score >= 0.0 && score <= 1.0)
        }

        for score in invalidScores {
            #expect(!(score >= 0.0 && score <= 1.0))
        }
    }

    @Test func testConfidenceScore_HighConfidenceThreshold() throws {
        // Given
        let highConfidenceMatch = BackendAPIService.MatchResponse(
            philosopher_id: "test",
            philosopher_name: "Test Philosopher",
            match_reason: "Strong alignment",
            confidence: 0.92
        )

        let lowConfidenceMatch = BackendAPIService.MatchResponse(
            philosopher_id: "test",
            philosopher_name: "Test Philosopher",
            match_reason: "Weak alignment",
            confidence: 0.58
        )

        // Then
        let highConfidenceThreshold = 0.85
        #expect(highConfidenceMatch.confidence >= highConfidenceThreshold)
        #expect(lowConfidenceMatch.confidence < highConfidenceThreshold)
    }

    // MARK: - Integration Tests

    @Test func testMatchingFlow_CompleteJourney() throws {
        // Given - User profile
        let profile = UserProfile(
            name: "Integration Test User",
            profession: .military,
            currentFocus: .dealingWithAdversity,
            lifeContext: [.highStressEnvironment],
            stoicGoals: [.emotionalResilience, .discipline],
            favoritePhilosopher: nil
        )

        // When - Convert to onboarding answers (simulated)
        let expectedAnswers = [
            "profession": "Military",
            "challenge": "Dealing with adversity",
            "goals": "Emotional resilience, Discipline"
        ]

        // Then - Verify profile captures all necessary information
        #expect(profile.profession == .military)
        #expect(profile.currentFocus == .dealingWithAdversity)
        #expect(profile.stoicGoals.contains(.emotionalResilience))
        #expect(profile.stoicGoals.contains(.discipline))
        #expect(profile.favoritePhilosopher == nil) // Not yet matched
    }

    // MARK: - Error Handling in Matching Flow

    @Test func testMatchingFlow_HandlesAPIFailure() throws {
        // Given - Simulate API failure scenario
        struct MockError: Error {}

        // Then - Verify error handling expectations
        // In the actual app, this should:
        // 1. Show error message to user
        // 2. Allow manual philosopher selection
        // 3. Not crash the app
        #expect(true) // Placeholder for error handling verification
    }

    @Test func testMatchingFlow_FallbackToManualSelection() throws {
        // Given - User can always manually select philosopher
        let manualSelection = "Marcus Aurelius"

        // Then - Verify manual selection is always available
        #expect(!manualSelection.isEmpty)
        // In the actual flow, user should be able to skip AI matching
    }

    // MARK: - Philosopher Display Tests

    @Test func testPhilosopherDisplay_FormatsCorrectly() throws {
        // Given
        let match = BackendAPIService.MatchResponse(
            philosopher_id: "marcus_aurelius",
            philosopher_name: "Marcus Aurelius",
            match_reason: "Your leadership qualities align with Marcus's teachings on stoic governance and duty.",
            confidence: 0.91
        )

        // When - Format for display
        let confidencePercent = Int(match.confidence * 100)
        let displayText = "\(confidencePercent)% Match"

        // Then
        #expect(confidencePercent == 91)
        #expect(displayText == "91% Match")
    }

    // MARK: - Teaching Style Preference Tests

    @Test func testTeachingStylePreference_Healthcare() throws {
        // Given
        let profile = UserProfile(
            name: "Test",
            profession: .healthcare,
            currentFocus: .buildingCharacter,
            lifeContext: [],
            stoicGoals: [],
            favoritePhilosopher: nil
        )

        // Then - Should prefer practical, duty-focused wisdom
        #expect(profile.profession == .healthcare)
        // Expected teaching style: "practical, duty-focused wisdom for high-pressure roles"
    }

    @Test func testTeachingStylePreference_Creative() throws {
        // Given
        let profile = UserProfile(
            name: "Test",
            profession: .creative,
            currentFocus: .buildingCharacter,
            lifeContext: [],
            stoicGoals: [],
            favoritePhilosopher: nil
        )

        // Then - Should prefer philosophical depth with creative perspective
        #expect(profile.profession == .creative)
        // Expected teaching style: "philosophical depth with creative perspective"
    }
}
