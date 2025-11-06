//
//  ThemeManager.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var appTheme: AppTheme = .system

    enum AppTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }

    var colorScheme: ColorScheme? {
        switch appTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Use system default
        }
    }
}

// Modern iOS color scheme
struct AppColors {
    // Backgrounds
    static let primaryBackground = Color.black
    static let secondaryBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let tertiaryBackground = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let quaternaryBackground = Color(red: 58/255, green: 58/255, blue: 60/255)

    // Light mode backgrounds
    static let lightPrimaryBackground = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let lightSecondaryBackground = Color.white
    static let lightTertiaryBackground = Color(red: 229/255, green: 229/255, blue: 234/255)

    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 235/255, green: 235/255, blue: 245/255, opacity: 0.6)
    static let tertiaryText = Color(red: 235/255, green: 235/255, blue: 245/255, opacity: 0.3)

    // Light mode text colors
    static let lightPrimaryText = Color.black
    static let lightSecondaryText = Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6)
    static let lightTertiaryText = Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.3)

    // Helper functions
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? primaryBackground : lightPrimaryBackground
    }

    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryBackground : lightSecondaryBackground
    }

    static func tertiaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? tertiaryBackground : lightTertiaryBackground
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? primaryText : lightPrimaryText
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryText : lightSecondaryText
    }
}

