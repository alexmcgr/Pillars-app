//
//  FocusChoice.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import Foundation
import SwiftUI

// Utility for app-specific day boundary (4am)
struct DateUtils {
    static let boundaryHour: Int = 4

    static func appStartOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        let shifted = calendar.date(byAdding: .hour, value: -boundaryHour, to: date) ?? date
        return calendar.startOfDay(for: shifted)
    }

    static func appIsDateInToday(_ date: Date, calendar: Calendar = .current) -> Bool {
        appStartOfDay(for: date, calendar: calendar) == appStartOfDay(for: Date(), calendar: calendar)
    }

    static func appIsSameAppDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        appStartOfDay(for: lhs, calendar: calendar) == appStartOfDay(for: rhs, calendar: calendar)
    }

    static func appToday(calendar: Calendar = .current) -> Date {
        appStartOfDay(for: Date(), calendar: calendar)
    }

    static func appYesterday(calendar: Calendar = .current) -> Date {
        let today = appToday(calendar: calendar)
        return calendar.date(byAdding: .day, value: -1, to: today) ?? today
    }

    static func appTomorrow(calendar: Calendar = .current) -> Date {
        let today = appToday(calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }
}

// Represents a focus choice with a label and color
struct FocusChoice: Identifiable, Codable {
    let id: Int
    let color: ColorData

    // Computed property to get the label (custom or default)
    var label: String {
        FocusLabelManager.shared.getLabel(for: id)
    }

    // Five focus options with macOS tag colors
    static let defaultChoices: [FocusChoice] = [
        FocusChoice(id: 0, color: ColorData(red: 0/255, green: 122/255, blue: 255/255)), // Blue
        FocusChoice(id: 1, color: ColorData(red: 52/255, green: 199/255, blue: 89/255)), // Green
        FocusChoice(id: 2, color: ColorData(red: 255/255, green: 59/255, blue: 48/255)), // Red
        FocusChoice(id: 3, color: ColorData(red: 255/255, green: 149/255, blue: 0/255)), // Orange
        FocusChoice(id: 4, color: ColorData(red: 175/255, green: 82/255, blue: 222/255))  // Purple
    ]
}

// Helper to store Color as Codable data
struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

// Represents a daily focus selection
struct DailyFocus: Codable {
    let date: Date
    let choiceId: Int
    var journalEntry: String?

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
