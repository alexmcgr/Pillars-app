//
//  PillarsApp.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI
import UserNotifications

@main
struct PillarsApp: App {
    @StateObject private var focusStore = FocusStore()
    
    init() {
        // Set app icon based on today's focus when app launches
        updateAppIcon()
        // Ensure local notifications display while the app is in the foreground
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
        // Request notification permissions and schedule daily journal reminders
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("Notification permission granted")
            }
        }
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

// MARK: - Notification Delegate (foreground presentation)
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    private override init() { super.init() }

    // Show banner/sound even when app is active
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // Handle tap on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // Route based on notification type
        if identifier.hasPrefix("todo_") {
            // Todo notification - just go to home (no specific action needed)
            // The app will open and show today's todos
        } else if identifier == "journal_daily_reminder" {
            // Journal notification - open journal sheet
            NotificationCenter.default.post(name: .openJournalFromNotification, object: nil)
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    static let openJournalFromNotification = Notification.Name("openJournalFromNotification")
}
