//
//  FocusChoice.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import Foundation
import SwiftUI

// Represents a focus choice with a label and color
struct FocusChoice: Identifiable, Codable {
    let id: Int
    let label: String
    let color: ColorData
    
    // Five focus options with macOS tag colors
    static let defaultChoices: [FocusChoice] = [
        FocusChoice(id: 0, label: "Creativity", color: ColorData(red: 0/255, green: 122/255, blue: 255/255)), // Blue
        FocusChoice(id: 1, label: "Fitness", color: ColorData(red: 52/255, green: 199/255, blue: 89/255)), // Green
        FocusChoice(id: 2, label: "Relationships", color: ColorData(red: 255/255, green: 59/255, blue: 48/255)), // Red
        FocusChoice(id: 3, label: "Entertainment", color: ColorData(red: 255/255, green: 149/255, blue: 0/255)), // Orange
        FocusChoice(id: 4, label: "Balance", color: ColorData(red: 175/255, green: 82/255, blue: 222/255))  // Purple
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
    
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

