//
//  StreaksView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import SwiftUI

// MARK: - Mini Card for Home Screen
struct StreaksCard: View {
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    @State private var showingFullView = false
    @Environment(\.colorScheme) var colorScheme

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue
        }
        return choice.color.color
    }

    private var currentFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    private var relevantStreaks: [Streak] {
        guard let focusId = currentFocusId else {
            // Filter out completed streaks and show up to 2
            let incomplete = streakManager.streaks.filter { !streakManager.isStreakCompleteThisWeek($0) }
            return Array(incomplete.prefix(2))
        }

        // Filter streaks that are associated with current focus AND not complete this week
        let filtered = streakManager.streaks.filter { streak in
            let isRelevant = streak.associatedFocusIds.isEmpty || streak.associatedFocusIds.contains(focusId)
            let isIncomplete = !streakManager.isStreakCompleteThisWeek(streak)
            return isRelevant && isIncomplete
        }

        return Array(filtered.prefix(2))
    }

    var body: some View {
        Button(action: {
            showingFullView = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(focusColor)

                    Text("Streaks")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                if streakManager.streaks.isEmpty {
                    Text("No active streaks")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(relevantStreaks) { streak in
                            StreakMiniRow(
                                streak: streak,
                                streakManager: streakManager,
                                focusStore: focusStore,
                                selectedDate: selectedDate
                            )
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.tertiaryBackground(for: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFullView) {
            StreaksDetailView(streakManager: streakManager, focusStore: focusStore)
        }
    }
}

struct StreakMiniRow: View {
    let streak: Streak
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    @Environment(\.colorScheme) var colorScheme

    private var progress: (completed: Int, target: Int) {
        streakManager.getWeekProgress(for: streak, date: selectedDate)
    }

    private var isCompletedToday: Bool {
        streakManager.isCompletedToday(streakId: streak.id, date: selectedDate)
    }

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue
        }
        return choice.color.color
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: streak.icon)
                .font(.system(size: 24))
                .foregroundColor(focusColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(streak.name)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Text("\(progress.completed)/\(progress.target) this week")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                if !isCompletedToday {
                    let todayFocus = focusStore.getFocus(for: selectedDate)
                    streakManager.markComplete(streakId: streak.id, date: selectedDate, focusId: todayFocus?.choiceId)
                }
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(focusColor)
                    .font(.system(size: 24))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isCompletedToday)
        }
    }
}

// MARK: - Full Detail View
struct StreaksDetailView: View {
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    @State private var showingAddStreak = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var focusColor: Color {
        focusStore.getTodayColor() ?? .blue
    }

    var body: some View {
        let sortedStreaks = streakManager.getSortedStreaks()

        return NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if streakManager.streaks.isEmpty {
                    VStack(spacing: 16) {
                        Text("No Streaks Yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Create your first streak to get started")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 40)
                } else {
                    List {
                        ForEach(sortedStreaks) { streak in
                            StreakDetailRow(
                                streak: streak,
                                streakManager: streakManager,
                                focusStore: focusStore
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Streaks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.primaryText(for: colorScheme))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddStreak = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(focusColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddStreak) {
            CreateStreakView(streakManager: streakManager, focusStore: focusStore)
        }
    }
}

struct StreakDetailRow: View {
    let streak: Streak
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEdit = false

    private var progress: (completed: Int, target: Int) {
        streakManager.getCurrentWeekProgress(for: streak)
    }

    private var isComplete: Bool {
        streakManager.isStreakCompleteThisWeek(streak)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: streak.icon)
                    .font(.system(size: 32))
                    .foregroundColor(focusStore.getTodayColor() ?? .blue)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(streak.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                    Text(streakDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button(action: {
                        let todayFocus = focusStore.getFocus(for: Date())
                        streakManager.markComplete(streakId: streak.id, focusId: todayFocus?.choiceId)
                    }) {
                        Label("Mark Complete", systemImage: "checkmark")
                    }

                    Button(action: {
                        showingEdit = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        streakManager.deleteStreak(streak)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                }
                .sheet(isPresented: $showingEdit) {
                    EditStreakView(streak: streak, streakManager: streakManager, focusStore: focusStore)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(isComplete ? Color.green : focusStore.getTodayColor() ?? .blue)
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(progress.completed) / CGFloat(progress.target))), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(progress.completed) / \(progress.target)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isComplete ? .green : .secondary)

                Spacer()

                if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
    }

    private var streakDescription: String {
        return "\(streak.frequencyPerWeek)x per week"
    }
}

// MARK: - Create Streak View
struct CreateStreakView: View {
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var icon: String = "star.fill"
    @State private var name: String = ""
    @State private var frequency: Int = 3
    @State private var associatedFocusIds: Set<Int>
    @State private var showingIconPicker = false

    init(streakManager: StreakManager, focusStore: FocusStore) {
        self.streakManager = streakManager
        self.focusStore = focusStore

        // Default to current day's focus if set
        let currentFocusId = focusStore.getFocus(for: Date())?.choiceId ?? 0
        _associatedFocusIds = State(initialValue: currentFocusId != -1 ? [currentFocusId] : [])
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(action: {
                            showingIconPicker = true
                        }) {
                            Image(systemName: icon)
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.primaryText(for: colorScheme))
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(PlainButtonStyle())

                        TextField("Streak Name", text: $name)
                            .foregroundColor(AppColors.primaryText(for: colorScheme))
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency: \(frequency) time\(frequency == 1 ? "" : "s") per week")
                            .foregroundColor(AppColors.primaryText(for: colorScheme))

                        Slider(value: Binding(
                            get: { Double(frequency) },
                            set: { frequency = Int($0) }
                        ), in: 1...7, step: 1)
                    }
                }

                Section("Tags") {
                    ForEach(FocusChoice.defaultChoices) { choice in
                        Toggle(isOn: Binding(
                            get: { associatedFocusIds.contains(choice.id) },
                            set: { isOn in
                                if isOn {
                                    associatedFocusIds.insert(choice.id)
                                } else {
                                    associatedFocusIds.remove(choice.id)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(choice.color.color)
                                    .frame(width: 12, height: 12)
                                Text(choice.label)
                                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStreak()
                    }
                    .disabled(name.isEmpty || icon.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                SFSymbolPicker(selectedIcon: $icon)
            }
        }
    }

    private func saveStreak() {
        let streak = Streak(
            icon: icon,
            name: name,
            frequencyPerWeek: frequency,
            streakType: .simple,
            associatedFocusIds: Array(associatedFocusIds)
        )

        streakManager.addStreak(streak)
        dismiss()
    }
}

// MARK: - Edit Streak View
struct EditStreakView: View {
    let streak: Streak
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var focusStore: FocusStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var icon: String
    @State private var name: String
    @State private var frequency: Int
    @State private var associatedFocusIds: Set<Int>
    @State private var showingIconPicker = false

    init(streak: Streak, streakManager: StreakManager, focusStore: FocusStore) {
        self.streak = streak
        self.streakManager = streakManager
        self.focusStore = focusStore

        _icon = State(initialValue: streak.icon)
        _name = State(initialValue: streak.name)
        _frequency = State(initialValue: streak.frequencyPerWeek)
        _associatedFocusIds = State(initialValue: Set(streak.associatedFocusIds))
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(action: {
                            showingIconPicker = true
                        }) {
                            Image(systemName: icon)
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.primaryText(for: colorScheme))
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(PlainButtonStyle())

                        TextField("Streak Name", text: $name)
                            .foregroundColor(AppColors.primaryText(for: colorScheme))
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency: \(frequency) time\(frequency == 1 ? "" : "s") per week")
                            .foregroundColor(AppColors.primaryText(for: colorScheme))

                        Slider(value: Binding(
                            get: { Double(frequency) },
                            set: { frequency = Int($0) }
                        ), in: 1...7, step: 1)
                    }
                }

                Section("Tags") {
                    ForEach(FocusChoice.defaultChoices) { choice in
                        Toggle(isOn: Binding(
                            get: { associatedFocusIds.contains(choice.id) },
                            set: { isOn in
                                if isOn {
                                    associatedFocusIds.insert(choice.id)
                                } else {
                                    associatedFocusIds.remove(choice.id)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(choice.color.color)
                                    .frame(width: 12, height: 12)
                                Text(choice.label)
                                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStreak()
                    }
                    .disabled(name.isEmpty || icon.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                SFSymbolPicker(selectedIcon: $icon)
            }
        }
    }

    private func saveStreak() {
        var updatedStreak = streak
        updatedStreak.icon = icon
        updatedStreak.name = name
        updatedStreak.frequencyPerWeek = frequency
        updatedStreak.streakType = .simple
        updatedStreak.associatedFocusIds = Array(associatedFocusIds)

        streakManager.updateStreak(updatedStreak)
        dismiss()
    }
}
