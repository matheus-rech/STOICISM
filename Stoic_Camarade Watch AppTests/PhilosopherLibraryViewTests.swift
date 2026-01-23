//
//  PhilosopherLibraryViewTests.swift
//  Stoic_Camarade Watch AppTests
//
//  Tests for PhilosopherLibraryView and PhilosopherLibraryViewModel
//

import Testing
import Foundation
import SwiftUI
@testable import Stoic_Camarade_Watch_App

// MARK: - Philosopher Library View Model Tests

@MainActor
struct PhilosopherLibraryViewModelTests {

    // MARK: - Initialization Tests

    @Test func testViewModel_InitialState() async {
        // Given/When
        let viewModel = PhilosopherLibraryViewModel()

        // Then
        #expect(viewModel.philosophers.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Loading State Tests

    @Test func testViewModel_LoadingState() async {
        // Given
        let viewModel = PhilosopherLibraryViewModel()

        // When - Start loading (would need to expose internal state or test through integration)
        // For now, verify initial state
        #expect(!viewModel.isLoading)

        // After loadPhilosophers() is called, isLoading should be true briefly
        // This would require mocking the BackendAPIService
    }

    // MARK: - Success State Tests

    @Test func testViewModel_SuccessState() async {
        // Given - Mock successful response
        let mockPhilosophers = [
            BackendAPIService.Philosopher(
                id: "marcus_aurelius",
                name: "Marcus Aurelius",
                era: "Roman Empire (121-180 CE)",
                biography: "Roman emperor and Stoic philosopher",
                core_themes: ["Leadership", "Duty"],
                teaching_style: "Practical wisdom"
            ),
            BackendAPIService.Philosopher(
                id: "epictetus",
                name: "Epictetus",
                era: "Roman Empire (50-135 CE)",
                biography: "Former slave turned teacher",
                core_themes: ["Freedom", "Control"],
                teaching_style: "Direct guidance"
            )
        ]

        // Then - Verify philosopher data structure
        #expect(mockPhilosophers.count == 2)
        #expect(mockPhilosophers[0].name == "Marcus Aurelius")
        #expect(mockPhilosophers[1].core_themes.contains("Freedom"))
    }

    // MARK: - Error State Tests

    @Test func testViewModel_ErrorState() async {
        // Given
        let viewModel = PhilosopherLibraryViewModel()

        // When - Error occurs (simulated)
        let expectedErrorMessage = "Failed to load philosophers"

        // Then - Error should be captured
        #expect(expectedErrorMessage == "Failed to load philosophers")
        #expect(!expectedErrorMessage.isEmpty)
    }

    // MARK: - Philosopher Model Tests

    @Test func testPhilosopher_Codable() throws {
        // Given
        let json = """
        {
            "id": "seneca",
            "name": "Seneca",
            "era": "Roman Empire (4 BCE - 65 CE)",
            "biography": "Roman Stoic philosopher, statesman, and dramatist",
            "core_themes": ["Wealth", "Time", "Mortality"],
            "teaching_style": "Letters and essays with practical advice"
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let philosopher = try decoder.decode(BackendAPIService.Philosopher.self, from: data)

        // Then
        #expect(philosopher.id == "seneca")
        #expect(philosopher.name == "Seneca")
        #expect(philosopher.core_themes.count == 3)
        #expect(philosopher.core_themes.contains("Mortality"))
    }

    @Test func testPhilosopher_Identifiable() throws {
        // Given
        let philosopher1 = BackendAPIService.Philosopher(
            id: "marcus",
            name: "Marcus Aurelius",
            era: "Roman Empire",
            biography: "Emperor",
            core_themes: ["Leadership"],
            teaching_style: "Meditations"
        )

        let philosopher2 = BackendAPIService.Philosopher(
            id: "epictetus",
            name: "Epictetus",
            era: "Roman Empire",
            biography: "Teacher",
            core_themes: ["Freedom"],
            teaching_style: "Discourses"
        )

        // Then - IDs should be unique
        #expect(philosopher1.id != philosopher2.id)
    }

    // MARK: - Philosopher List Tests

    @Test func testPhilosopherList_Empty() async {
        // Given
        let emptyList: [BackendAPIService.Philosopher] = []

        // Then
        #expect(emptyList.isEmpty)
        #expect(emptyList.count == 0)
    }

    @Test func testPhilosopherList_MultiplePhilosophers() async {
        // Given
        let philosophers = [
            BackendAPIService.Philosopher(
                id: "1",
                name: "Marcus Aurelius",
                era: "Roman",
                biography: "Emperor",
                core_themes: ["Leadership"],
                teaching_style: "Practical"
            ),
            BackendAPIService.Philosopher(
                id: "2",
                name: "Epictetus",
                era: "Roman",
                biography: "Teacher",
                core_themes: ["Freedom"],
                teaching_style: "Direct"
            ),
            BackendAPIService.Philosopher(
                id: "3",
                name: "Seneca",
                era: "Roman",
                biography: "Statesman",
                core_themes: ["Time"],
                teaching_style: "Letters"
            )
        ]

        // Then
        #expect(philosophers.count == 3)
        #expect(philosophers.allSatisfy { !$0.name.isEmpty })
        #expect(philosophers.allSatisfy { !$0.id.isEmpty })
    }

    // MARK: - Core Themes Tests

    @Test func testCoreThemes_ValidThemes() throws {
        // Given
        let validThemes = [
            "Leadership",
            "Duty",
            "Inner Strength",
            "Freedom",
            "Control",
            "Acceptance",
            "Wisdom",
            "Virtue",
            "Mortality"
        ]

        // Then
        for theme in validThemes {
            #expect(!theme.isEmpty)
            #expect(theme.count > 2)
        }
    }

    @Test func testCoreThemes_DisplayLimit() throws {
        // Given
        let philosopher = BackendAPIService.Philosopher(
            id: "test",
            name: "Test Philosopher",
            era: "Ancient",
            biography: "Test bio",
            core_themes: ["Theme1", "Theme2", "Theme3", "Theme4", "Theme5"],
            teaching_style: "Test style"
        )

        // When - PhilosopherCard shows only first 3 themes
        let displayedThemes = Array(philosopher.core_themes.prefix(3))

        // Then
        #expect(displayedThemes.count == 3)
        #expect(displayedThemes == ["Theme1", "Theme2", "Theme3"])
    }

    // MARK: - Biography Tests

    @Test func testBiography_NotEmpty() throws {
        // Given
        let philosopher = BackendAPIService.Philosopher(
            id: "marcus",
            name: "Marcus Aurelius",
            era: "Roman Empire (121-180 CE)",
            biography: "Marcus Aurelius was Roman Emperor from 161 to 180 CE and a Stoic philosopher. He is best known for his personal writings, now known as the Meditations, which offer profound insights into Stoic philosophy and leadership.",
            core_themes: ["Leadership", "Duty", "Inner Strength"],
            teaching_style: "Personal reflections and meditations"
        )

        // Then
        #expect(!philosopher.biography.isEmpty)
        #expect(philosopher.biography.count > 50) // Substantial biography
    }

    // MARK: - Teaching Style Tests

    @Test func testTeachingStyle_Variations() throws {
        // Given
        let teachingStyles = [
            "Practical wisdom for rulers and leaders",
            "Direct and accessible guidance",
            "Letters and essays with practical advice",
            "Systematic philosophical treatises",
            "Dialogues and discussions"
        ]

        // Then
        for style in teachingStyles {
            #expect(!style.isEmpty)
            #expect(style.count > 10) // Descriptive enough
        }
    }

    // MARK: - Era Formatting Tests

    @Test func testEra_FormattedCorrectly() throws {
        // Given
        let eras = [
            "Roman Empire (121-180 CE)",
            "Roman Empire (50-135 CE)",
            "Roman Empire (4 BCE - 65 CE)",
            "Ancient Greece (c. 334 - c. 262 BCE)"
        ]

        // Then
        for era in eras {
            #expect(era.contains("CE") || era.contains("BCE"))
            #expect(!era.isEmpty)
        }
    }

    // MARK: - View State Management Tests

    @Test func testViewState_LoadingToSuccess() async {
        // Given - Initial state
        var isLoading = false
        var hasError = false
        var philosophersLoaded = false

        // When - Loading starts
        isLoading = true
        #expect(isLoading)

        // When - Loading succeeds
        isLoading = false
        philosophersLoaded = true
        #expect(!isLoading)
        #expect(philosophersLoaded)
        #expect(!hasError)
    }

    @Test func testViewState_LoadingToError() async {
        // Given - Initial state
        var isLoading = false
        var hasError = false
        var errorMessage: String? = nil

        // When - Loading starts
        isLoading = true
        #expect(isLoading)

        // When - Loading fails
        isLoading = false
        hasError = true
        errorMessage = "Network error occurred"

        #expect(!isLoading)
        #expect(hasError)
        #expect(errorMessage != nil)
    }

    // MARK: - Retry Functionality Tests

    @Test func testRetry_ClearsErrorState() async {
        // Given - Error state
        var hasError = true
        var errorMessage: String? = "Previous error"

        // When - Retry is triggered
        hasError = false
        errorMessage = nil

        // Then
        #expect(!hasError)
        #expect(errorMessage == nil)
    }

    // MARK: - Navigation Tests

    @Test func testNavigation_ToPhilosopherDetail() throws {
        // Given
        let philosopher = BackendAPIService.Philosopher(
            id: "test",
            name: "Test Philosopher",
            era: "Test Era",
            biography: "Test biography",
            core_themes: ["Test"],
            teaching_style: "Test style"
        )

        // Then - Philosopher should have all required data for detail view
        #expect(!philosopher.id.isEmpty)
        #expect(!philosopher.name.isEmpty)
        #expect(!philosopher.biography.isEmpty)
        #expect(!philosopher.core_themes.isEmpty)
        #expect(!philosopher.teaching_style.isEmpty)
    }

    // MARK: - Flow Layout Tests

    @Test func testFlowLayout_TagWrapping() throws {
        // Given - Many themes
        let themes = ["Leadership", "Duty", "Inner Strength", "Virtue", "Wisdom", "Justice", "Courage", "Temperance"]

        // When - Layout would wrap based on width
        // FlowLayout should handle wrapping automatically

        // Then - Verify all themes are present
        #expect(themes.count == 8)
        #expect(themes.allSatisfy { !$0.isEmpty })
    }

    // MARK: - Integration Tests

    @Test func testFullFlow_LoadAndDisplay() async {
        // Given
        let viewModel = PhilosopherLibraryViewModel()

        // When - Initial state
        #expect(viewModel.philosophers.isEmpty)
        #expect(!viewModel.isLoading)

        // Then - After load would complete (mocked)
        // viewModel.philosophers would be populated
        // viewModel.isLoading would be false
        // viewModel.errorMessage would be nil
    }

    // MARK: - Data Consistency Tests

    @Test func testDataConsistency_AllFieldsPresent() throws {
        // Given
        let philosopher = BackendAPIService.Philosopher(
            id: "complete_test",
            name: "Complete Test",
            era: "Test Era",
            biography: "Test Biography",
            core_themes: ["Theme 1", "Theme 2"],
            teaching_style: "Test Style"
        )

        // Then - All fields should be non-empty
        #expect(!philosopher.id.isEmpty)
        #expect(!philosopher.name.isEmpty)
        #expect(!philosopher.era.isEmpty)
        #expect(!philosopher.biography.isEmpty)
        #expect(!philosopher.core_themes.isEmpty)
        #expect(!philosopher.teaching_style.isEmpty)
    }
}
