//
//  PillarsApp.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

@main
struct PillarsApp: App {
    @StateObject private var focusStore = FocusStore()
    
    init() {
        // Set app icon based on today's focus when app launches
        updateAppIcon()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    updateAppIcon()
                }
        }
    }
    
    private func updateAppIcon() {
        if let todayFocus = focusStore.getTodayFocus() {
            AppIconManager.shared.setIcon(for: todayFocus.choiceId)
        }
    }
}
