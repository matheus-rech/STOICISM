//
//  TomorrowFocusView.swift
//  StoicCamarade Watch App
//
//  Tomorrow's priorities with stoic "In My Control" sorting
//

import SwiftUI
import Combine

// MARK: - Priority Model

struct Priority: Codable, Identifiable {
    let id: UUID
    var title: String
    var isInControl: Bool
    var isCompleted: Bool
    let createdAt: Date

    init(title: String, isInControl: Bool = true) {
        self.id = UUID()
        self.title = title
        self.isInControl = isInControl
        self.isCompleted = false
        self.createdAt = Date()
    }
}

// MARK: - Priority Manager

class PriorityManager: ObservableObject {
    static let shared = PriorityManager()

    @Published var priorities: [Priority] = []
    @Published var tomorrowsFocus: String = ""

    private let prioritiesKey = "stoic_priorities"
    private let focusKey = "stoic_tomorrow_focus"

    init() {
        loadData()
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: prioritiesKey),
           let decoded = try? JSONDecoder().decode([Priority].self, from: data) {
            priorities = decoded
        }

        tomorrowsFocus = UserDefaults.standard.string(forKey: focusKey) ?? ""
    }

    func saveData() {
        if let encoded = try? JSONEncoder().encode(priorities) {
            UserDefaults.standard.set(encoded, forKey: prioritiesKey)
        }
        UserDefaults.standard.set(tomorrowsFocus, forKey: focusKey)
    }

    func addPriority(_ title: String, isInControl: Bool = true) {
        let priority = Priority(title: title, isInControl: isInControl)
        priorities.append(priority)
        saveData()
    }

    func toggleComplete(_ id: UUID) {
        if let index = priorities.firstIndex(where: { $0.id == id }) {
            priorities[index].isCompleted.toggle()
            saveData()
        }
    }

    func toggleControl(_ id: UUID) {
        if let index = priorities.firstIndex(where: { $0.id == id }) {
            priorities[index].isInControl.toggle()
            saveData()
        }
    }

    func removePriority(_ id: UUID) {
        priorities.removeAll { $0.id == id }
        saveData()
    }

    func clearCompleted() {
        priorities.removeAll { $0.isCompleted }
        saveData()
    }

    var inControlPriorities: [Priority] {
        priorities.filter { $0.isInControl && !$0.isCompleted }
    }

    var notInControlPriorities: [Priority] {
        priorities.filter { !$0.isInControl && !$0.isCompleted }
    }

    var completedCount: Int {
        priorities.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        priorities.count
    }
}

// MARK: - Tomorrow's Focus View

struct TomorrowFocusView: View {
    @ObservedObject private var manager = PriorityManager.shared
    @State private var showingAddPriority = false
    @State private var newPriorityText = ""
    @State private var showingFocusComplete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Today's Focus banner (if set)
                if !manager.tomorrowsFocus.isEmpty {
                    focusBanner
                }

                // Priorities list
                if manager.priorities.isEmpty {
                    emptyState
                } else {
                    prioritiesList
                }

                // Add button
                addButton
            }
            .padding()
        }
        .navigationTitle("Priorities")
        .sheet(isPresented: $showingAddPriority) {
            addPrioritySheet
        }
        .sheet(isPresented: $showingFocusComplete) {
            focusCompleteSheet
        }
    }

    // MARK: - Focus Banner

    private var focusBanner: some View {
        VStack(spacing: 8) {
            Text("Tomorrow's Focus:")
                .font(.system(size: 10))
                .foregroundColor(.gray)

            Text(manager.tomorrowsFocus)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Focus on virtue message
            Text("My Reactions Only.")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Priorities Set")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("Add what's in your control")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding()
    }

    // MARK: - Priorities List

    private var prioritiesList: some View {
        VStack(spacing: 12) {
            // In Control Section
            if !manager.inControlPriorities.isEmpty {
                sectionHeader("In My Control", color: .green)

                ForEach(manager.inControlPriorities) { priority in
                    PriorityRow(priority: priority, manager: manager)
                }
            }

            // Not In Control Section
            if !manager.notInControlPriorities.isEmpty {
                sectionHeader("Not In My Control", color: .red)

                ForEach(manager.notInControlPriorities) { priority in
                    PriorityRow(priority: priority, manager: manager)
                }
            }

            // Completion status
            if manager.completedCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(manager.completedCount)/\(manager.totalCount) done")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Spacer()

                    if manager.completedCount == manager.inControlPriorities.count + manager.completedCount {
                        Button(action: { showingFocusComplete = true }) {
                            Text("Complete")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            Spacer()
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: { showingAddPriority = true }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Priority")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Add Priority Sheet

    private var addPrioritySheet: some View {
        VStack(spacing: 16) {
            Text("Add Priority")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("What needs to be done?", text: $newPriorityText)
                .font(.system(size: 12))
                .padding(10)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)

            // Control toggle buttons
            HStack(spacing: 10) {
                Button(action: {
                    if !newPriorityText.isEmpty {
                        manager.addPriority(newPriorityText, isInControl: true)
                        newPriorityText = ""
                        showingAddPriority = false
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                        Text("In Control")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    if !newPriorityText.isEmpty {
                        manager.addPriority(newPriorityText, isInControl: false)
                        newPriorityText = ""
                        showingAddPriority = false
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                        Text("Not In Control")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }

    // MARK: - Focus Complete Sheet

    private var focusCompleteSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Plan Complete.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Focus on Virtue.")
                .font(.system(size: 12))
                .foregroundColor(.green)

            Button(action: {
                manager.clearCompleted()
                showingFocusComplete = false
            }) {
                Text("Open Planner")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

// MARK: - Priority Row

struct PriorityRow: View {
    let priority: Priority
    @ObservedObject var manager: PriorityManager

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button(action: { manager.toggleComplete(priority.id) }) {
                Image(systemName: priority.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(priority.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            // Title
            Text(priority.title)
                .font(.system(size: 12))
                .foregroundColor(priority.isCompleted ? .gray : .white)
                .strikethrough(priority.isCompleted)

            Spacer()

            // Control indicator
            if !priority.isCompleted {
                Button(action: { manager.toggleControl(priority.id) }) {
                    Image(systemName: priority.isInControl ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(priority.isInControl ? .green : .red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }
}

#Preview {
    NavigationView {
        TomorrowFocusView()
    }
}
