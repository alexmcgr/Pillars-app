//
//  NotificationManager.swift
//  Pillars
//
//  Created by Cascade on 11/7/25.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let defaults = UserDefaults.standard
    private let notificationTimeKey = "journalNotificationTime"
    private let todoAMTimeKey = "todoAMReminderTime"
    private let todoPMTimeKey = "todoPMReminderTime"

    @Published var notificationTime: Date {
        didSet {
            saveNotificationTime()
            rescheduleNotifications()
        }
    }

    @Published var todoAMTime: Date {
        didSet {
            defaults.set(todoAMTime, forKey: todoAMTimeKey)
        }
    }

    @Published var todoPMTime: Date {
        didSet {
            defaults.set(todoPMTime, forKey: todoPMTimeKey)
        }
    }

    private init() {
        // Load saved time or default to 10pm for journal
        if let savedTime = defaults.object(forKey: notificationTimeKey) as? Date {
            self.notificationTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 22
            components.minute = 0
            self.notificationTime = Calendar.current.date(from: components) ?? Date()
        }

        // Load or default AM time (9am)
        if let savedAM = defaults.object(forKey: todoAMTimeKey) as? Date {
            self.todoAMTime = savedAM
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.todoAMTime = Calendar.current.date(from: components) ?? Date()
        }

        // Load or default PM time (7pm)
        if let savedPM = defaults.object(forKey: todoPMTimeKey) as? Date {
            self.todoPMTime = savedPM
        } else {
            var components = DateComponents()
            components.hour = 19
            components.minute = 0
            self.todoPMTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    private func saveNotificationTime() {
        defaults.set(notificationTime, forKey: notificationTimeKey)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
                if granted {
                    self.rescheduleNotifications()
                }
            }
        }
    }

    func rescheduleNotifications() {
        cancelJournalReminders()
        scheduleDailyJournalReminder()
    }

    // Schedule a daily reminder at the configured time
    private func scheduleDailyJournalReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Journal"
        content.body = "You haven't completed your daily journal yet today"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "journal_daily_reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func cancelJournalReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["journal_daily_reminder", "journal_test_reminder"]
        )
    }

    // MARK: - Todo Reminders

    func scheduleTodoReminder(todoId: String, title: String, date: Date, reminderTime: Date) -> String {
        let notificationId = "todo_\(todoId)"
        let content = UNMutableNotificationContent()
        content.title = "Todo Reminder"
        content.body = title
        content.sound = .default

        // Combine the date and reminder time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: combined, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling todo notification: \(error)")
            }
        }

        return notificationId
    }

    func cancelTodoReminder(notificationId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
