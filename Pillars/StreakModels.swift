//
//  StreakModels.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import Foundation
import SwiftUI

// MARK: - Streak Model
struct Streak: Identifiable, Codable {
    let id: UUID
    var icon: String // Emoji
    var name: String
    var frequencyPerWeek: Int // 1-7
    var streakType: StreakType
    var associatedFocusIds: [Int] // Which focus modes this streak should appear for
    var createdDate: Date

    init(
        id: UUID = UUID(),
        icon: String,
        name: String,
        frequencyPerWeek: Int,
        streakType: StreakType,
        associatedFocusIds: [Int] = [],
        createdDate: Date = Date()
    ) {
        self.id = id
        self.icon = icon
        self.name = name
        self.frequencyPerWeek = frequencyPerWeek
        self.streakType = streakType
        self.associatedFocusIds = associatedFocusIds
        self.createdDate = createdDate
    }
}

enum StreakType: Codable, Equatable {
    case simple // Just track frequency
    case specificFocus(focusId: Int) // Must be specific focus
    case allFocusTypes // One of each focus type per week

    enum CodingKeys: String, CodingKey {
        case type
        case focusId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "simple":
            self = .simple
        case "specificFocus":
            let focusId = try container.decode(Int.self, forKey: .focusId)
            self = .specificFocus(focusId: focusId)
        case "allFocusTypes":
            self = .allFocusTypes
        default:
            self = .simple
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .simple:
            try container.encode("simple", forKey: .type)
        case .specificFocus(let focusId):
            try container.encode("specificFocus", forKey: .type)
            try container.encode(focusId, forKey: .focusId)
        case .allFocusTypes:
            try container.encode("allFocusTypes", forKey: .type)
        }
    }
}

// MARK: - Streak Completion
struct StreakCompletion: Identifiable, Codable {
    let id: UUID
    let streakId: UUID
    let date: Date
    let focusId: Int? // Optional: which focus was active when completed

    init(id: UUID = UUID(), streakId: UUID, date: Date, focusId: Int? = nil) {
        self.id = id
        self.streakId = streakId
        self.date = date
        self.focusId = focusId
    }
}

// MARK: - Streak Manager
class StreakManager: ObservableObject {
    @Published var streaks: [Streak] = []
    @Published var completions: [StreakCompletion] = []

    private let userDefaults = UserDefaults.standard
    private let streaksKey = "streaks"
    private let completionsKey = "streakCompletions"

    init() {
        loadStreaks()
        loadCompletions()
    }

    // MARK: - Streak Management
    func addStreak(_ streak: Streak) {
        streaks.append(streak)
        saveStreaks()
    }

    func updateStreak(_ streak: Streak) {
        if let index = streaks.firstIndex(where: { $0.id == streak.id }) {
            streaks[index] = streak
            saveStreaks()
        }
    }

    func deleteStreak(_ streak: Streak) {
        streaks.removeAll(where: { $0.id == streak.id })
        completions.removeAll(where: { $0.streakId == streak.id })
        saveStreaks()
        saveCompletions()
    }

    // MARK: - Completion Management
    func markComplete(streakId: UUID, date: Date = Date(), focusId: Int? = nil) {
        let completion = StreakCompletion(streakId: streakId, date: date, focusId: focusId)
        completions.append(completion)
        saveCompletions()
    }

    func removeCompletion(_ completion: StreakCompletion) {
        completions.removeAll(where: { $0.id == completion.id })
        saveCompletions()
    }

    // MARK: - Streak Statistics
    private func getWeekInterval(for date: Date) -> DateInterval? {
        var calendar = Calendar.current
        // Ensure Sunday is the first day of the week
        calendar.firstWeekday = 1 // 1 = Sunday, 2 = Monday, etc.
        return calendar.dateInterval(of: .weekOfYear, for: date)
    }

    func getCompletionsForCurrentWeek(streakId: UUID) -> [StreakCompletion] {
        let now = Date()
        guard let weekInterval = getWeekInterval(for: now) else {
            return []
        }

        return completions.filter { completion in
            completion.streakId == streakId &&
            completion.date >= weekInterval.start &&
            completion.date < weekInterval.end
        }
    }

    func getCompletionsForWeek(streakId: UUID, date: Date) -> [StreakCompletion] {
        guard let weekInterval = getWeekInterval(for: date) else {
            return []
        }

        return completions.filter { completion in
            completion.streakId == streakId &&
            completion.date >= weekInterval.start &&
            completion.date < weekInterval.end
        }
    }

    func isCompletedToday(streakId: UUID, date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        return completions.contains { completion in
            completion.streakId == streakId &&
            calendar.isDate(completion.date, inSameDayAs: normalizedDate)
        }
    }

    func getCurrentWeekProgress(for streak: Streak) -> (completed: Int, target: Int) {
        let completionsThisWeek = getCompletionsForCurrentWeek(streakId: streak.id)
        return (completionsThisWeek.count, streak.frequencyPerWeek)
    }

    func getWeekProgress(for streak: Streak, date: Date) -> (completed: Int, target: Int) {
        let completionsThisWeek = getCompletionsForWeek(streakId: streak.id, date: date)
        return (completionsThisWeek.count, streak.frequencyPerWeek)
    }

    func isStreakCompleteThisWeek(_ streak: Streak) -> Bool {
        let progress = getCurrentWeekProgress(for: streak)
        return progress.completed >= progress.target
    }

    func getSortedStreaks() -> [Streak] {
        return streaks.sorted { streakA, streakB in
            // Sort by most recently interacted with
            let aCompletionDate = completions
                .filter { $0.streakId == streakA.id }
                .max(by: { $0.date < $1.date })?.date ?? streakA.createdDate
            let bCompletionDate = completions
                .filter { $0.streakId == streakB.id }
                .max(by: { $0.date < $1.date })?.date ?? streakB.createdDate
            return aCompletionDate > bCompletionDate
        }
    }

    // MARK: - Persistence
    private func saveStreaks() {
        if let encoded = try? JSONEncoder().encode(streaks) {
            userDefaults.set(encoded, forKey: streaksKey)
        }
    }

    private func loadStreaks() {
        if let data = userDefaults.data(forKey: streaksKey),
           let decoded = try? JSONDecoder().decode([Streak].self, from: data) {
            streaks = decoded
        }
    }

    private func saveCompletions() {
        if let encoded = try? JSONEncoder().encode(completions) {
            userDefaults.set(encoded, forKey: completionsKey)
        }
    }

    private func loadCompletions() {
        if let data = userDefaults.data(forKey: completionsKey),
           let decoded = try? JSONDecoder().decode([StreakCompletion].self, from: data) {
            completions = decoded
        }
    }
}
