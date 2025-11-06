//
//  ContentView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var focusStore = FocusStore()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var showDailyFocusSplash = false
    @Environment(\.colorScheme) var systemColorScheme

    init() {
        // Set default value for dynamic app icon on first launch
        if UserDefaults.standard.object(forKey: "dynamicAppIcon") == nil {
            UserDefaults.standard.set(true, forKey: "dynamicAppIcon")
        }

        // Configure tab bar appearance for liquid glass effect
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(white: 0.1, alpha: 0.8)

        // Apply blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundEffect = blurEffect

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    private var activeColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    private var accentColor: Color {
        // Default to blue for tab bar accent
        Color(red: 0/255, green: 122/255, blue: 255/255)
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
            // Focus Tab
            FocusView(focusStore: focusStore)
                .tabItem {
                    Image(systemName: "circle.fill")
                    Text("Focus")
                }
                .tag(0)

            // Calendar Tab
            FullCalendarView(focusStore: focusStore)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)

            // Journal Tab
            JournalView(focusStore: focusStore)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Journal")
                }
                .tag(2)

            // Settings Tab
            SettingsView(focusStore: focusStore)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
            .background(AppColors.background(for: activeColorScheme))
            .accentColor(accentColor)
            .preferredColorScheme(themeManager.colorScheme)
            .onAppear {
                updateTabBarAppearance()
                checkAndShowDailySplash()
            }
            .onChange(of: accentColor) { _, _ in
                // Note: Tab bar appearance updates on app restart
                // UITabBar.appearance() changes don't apply dynamically (Apple limitation)
                updateTabBarAppearance()
            }
            .onChange(of: activeColorScheme) { _, _ in
                updateTabBarAppearance()
            }

            // Daily focus splash screen
            if showDailyFocusSplash {
                DailyFocusSplash(focusStore: focusStore, isPresented: $showDailyFocusSplash)
                    .transition(.opacity)
                    .zIndex(1)
                    .onChange(of: showDailyFocusSplash) { _, newValue in
                        if !newValue {
                            // Update tab bar with selected focus color after splash dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                updateTabBarAppearance()
                            }
                        }
                    }
            }
        }
    }

    private func checkAndShowDailySplash() {
        // TESTING MODE: Show splash on every app launch
        // TODO: Revert to once-per-day logic after testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showDailyFocusSplash = true
        }

        /* PRODUCTION CODE - Uncomment after testing:
        let lastSplashDateKey = "lastDailySplashDate"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let today = dateFormatter.string(from: Date())
        let lastSplashDate = UserDefaults.standard.string(forKey: lastSplashDateKey)

        // Show splash if we haven't shown it today
        if lastSplashDate != today {
            // Check if focus is already set for today
            let todayFocus = focusStore.getFocus(for: Date())
            if todayFocus == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showDailyFocusSplash = true
                }
            } else {
                // If focus is already set, update tab bar with that color immediately
                updateTabBarAppearance()
            }
            // Mark that we've shown the splash today
            UserDefaults.standard.set(today, forKey: lastSplashDateKey)
        }
        */
    }

    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        if activeColorScheme == .dark {
            appearance.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.backgroundEffect = blurEffect
        } else {
            appearance.backgroundColor = UIColor(white: 0.97, alpha: 0.8)
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
            appearance.backgroundEffect = blurEffect
        }

        // Set icon colors
        let uiAccentColor = UIColor(accentColor)
        appearance.stackedLayoutAppearance.selected.iconColor = uiAccentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: uiAccentColor]

        let unselectedColor = UIColor(white: activeColorScheme == .dark ? 0.6 : 0.4, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
