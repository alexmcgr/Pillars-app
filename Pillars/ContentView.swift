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
        }
        .background(backgroundColor)
        .accentColor(.white)
    }
}

#Preview {
    ContentView()
}
