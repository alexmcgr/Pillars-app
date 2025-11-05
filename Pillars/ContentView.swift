//
//  ContentView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var focusStore = FocusStore()
    @State private var selectedTab = 0

    // macOS dark grey background from the image
    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)

    init() {
        // Set default value for dynamic app icon on first launch
        if UserDefaults.standard.object(forKey: "dynamicAppIcon") == nil {
            UserDefaults.standard.set(true, forKey: "dynamicAppIcon")
        }
    }

    var body: some View {
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
        .background(backgroundColor)
        .accentColor(.white)
    }
}

#Preview {
    ContentView()
}
