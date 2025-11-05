//
//  FocusLabelManager.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import Foundation

class FocusLabelManager {
    static let shared = FocusLabelManager()

    private let userDefaults = UserDefaults.standard
    private let labelsKey = "customFocusLabels"

    // Default labels
    private let defaultLabels: [Int: String] = [
        0: "Creativity",
        1: "Fitness",
        2: "Relationships",
        3: "Entertainment",
        4: "Balance"
    ]

    private init() {}

    // Get the label for a focus choice ID
    func getLabel(for id: Int) -> String {
        let customLabels = getCustomLabels()
        return customLabels[id] ?? defaultLabels[id] ?? "Unknown"
    }

    // Set a custom label for a focus choice ID
    func setLabel(for id: Int, label: String) {
        var customLabels = getCustomLabels()
        if label.trimmingCharacters(in: .whitespaces).isEmpty {
            // If empty, remove custom label to fall back to default
            customLabels.removeValue(forKey: id)
        } else {
            customLabels[id] = label
        }
        saveCustomLabels(customLabels)
    }

    // Get all custom labels
    private func getCustomLabels() -> [Int: String] {
        if let data = userDefaults.data(forKey: labelsKey),
           let labels = try? JSONDecoder().decode([Int: String].self, from: data) {
            return labels
        }
        return [:]
    }

    // Save custom labels
    private func saveCustomLabels(_ labels: [Int: String]) {
        if let data = try? JSONEncoder().encode(labels) {
            userDefaults.set(data, forKey: labelsKey)
        }
    }

    // Reset all labels to defaults
    func resetToDefaults() {
        userDefaults.removeObject(forKey: labelsKey)
    }
}

