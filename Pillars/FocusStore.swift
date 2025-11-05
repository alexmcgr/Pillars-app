//
//  FocusStore.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import Foundation
import SwiftUI

class FocusStore: ObservableObject {
    @Published var selections: [String: DailyFocus] = [:]
    
    // Use App Group for sharing with widget
    private let userDefaults = UserDefaults(suiteName: "group.punchline.Pillars") ?? UserDefaults.standard
    private let selectionsKey = "focusSelections"
    
    init() {
        loadSelections()
    }
    
    // Get the focus selection for a specific date
    func getFocus(for date: Date) -> DailyFocus? {
        // Normalize date to start of day for consistent comparison
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let key = dateKey(for: normalizedDate)
        return selections[key]
    }
    
    // Set the focus selection for a specific date
    func setFocus(for date: Date, choiceId: Int) {
        // Normalize date to start of day for consistent comparison
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let key = dateKey(for: normalizedDate)
        let focus = DailyFocus(date: normalizedDate, choiceId: choiceId)
        selections[key] = focus
        saveSelections()
    }
    
    // Get today's focus
    func getTodayFocus() -> DailyFocus? {
        return getFocus(for: Date())
    }
    
    // Get the color for today's focus
    func getTodayColor() -> Color? {
        guard let todayFocus = getTodayFocus(),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == todayFocus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }
    
    // Helper to generate date key
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Save selections to UserDefaults
    private func saveSelections() {
        if let encoded = try? JSONEncoder().encode(selections) {
            userDefaults.set(encoded, forKey: selectionsKey)
        }
    }
    
    // Load selections from UserDefaults
    private func loadSelections() {
        if let data = userDefaults.data(forKey: selectionsKey),
           let decoded = try? JSONDecoder().decode([String: DailyFocus].self, from: data) {
            selections = decoded
        }
    }
}

