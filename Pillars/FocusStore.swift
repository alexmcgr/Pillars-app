//
//  FocusStore.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import Foundation
import SwiftUI
import UserNotifications

class FocusStore: ObservableObject {
    @Published var selections: [String: DailyFocus] = [:]
    @Published var dailyTodos: [String: [TodoItem]] = [:]

    // Use standard UserDefaults for data persistence
    private let userDefaults = UserDefaults.standard
    private let selectionsKey = "focusSelections"
    private let todosKey = "dailyTodos"
    private let migrationKey = "dataMigratedToStandard"

    init() {
        migrateIfNeeded()
        loadSelections()
        loadTodos()
    }

 

    // Get the focus selection for a specific date
    func getFocus(for date: Date) -> DailyFocus? {
        // Normalize date to app start of day (4am boundary) for consistent comparison
        let normalizedDate = DateUtils.appStartOfDay(for: date)
        let key = dateKey(for: normalizedDate)
        return selections[key]
    }

    // Set the focus selection for a specific date
    func setFocus(for date: Date, choiceId: Int) {
        // Normalize date to app start of day (4am boundary) for consistent comparison
        let normalizedDate = DateUtils.appStartOfDay(for: date)
        let key = dateKey(for: normalizedDate)

        // Preserve existing journal entry if there is one
        let existingJournal = selections[key]?.journalEntry
        var focus = DailyFocus(date: normalizedDate, choiceId: choiceId, journalEntry: existingJournal)
        selections[key] = focus
        saveSelections()

        // Update app icon if setting focus for app-today
        if DateUtils.appIsDateInToday(normalizedDate) {
            AppIconManager.shared.setIcon(for: choiceId)
        }
    }

    // Set the journal entry for a specific date
    func setJournalEntry(for date: Date, entry: String) {
        // Normalize date to app start of day (4am boundary) for consistent comparison
        let normalizedDate = DateUtils.appStartOfDay(for: date)
        let key = dateKey(for: normalizedDate)

        if var focus = selections[key] {
            // Update existing focus with journal entry
            focus.journalEntry = entry.isEmpty ? nil : entry
            selections[key] = focus
        } else {
            // Only store journal entries if there's a focus for that day
            return
        }
        saveSelections()
    }

    // Get the journal entry for a specific date
    func getJournalEntry(for date: Date) -> String? {
        return getFocus(for: date)?.journalEntry
    }

    // Get all journal entries for a specific month
    func getJournalEntries(for month: Date) -> [(date: Date, entry: String, focus: DailyFocus)] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        var entries: [(date: Date, entry: String, focus: DailyFocus)] = []

        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            if let focus = getFocus(for: currentDate),
               let journalEntry = focus.journalEntry,
               !journalEntry.trimmingCharacters(in: .whitespaces).isEmpty {
                entries.append((date: currentDate, entry: journalEntry, focus: focus))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Sort by date (newest first)
        return entries.sorted { $0.date > $1.date }
    }

    // Get all journal entries across all dates
    func getAllJournalEntries() -> [(date: Date, entry: String, focus: DailyFocus)] {
        var entries: [(date: Date, entry: String, focus: DailyFocus)] = []
        
        // Iterate through all stored selections
        for (dateKey, focus) in selections {
            // Parse the date key (format: "yyyy-MM-dd")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateKey),
               let journalEntry = focus.journalEntry,
               !journalEntry.trimmingCharacters(in: .whitespaces).isEmpty {
                entries.append((date: date, entry: journalEntry, focus: focus))
            }
        }
        
        // Sort by date (newest first)
        return entries.sorted { $0.date > $1.date }
    }

    // Get today's focus
    func getTodayFocus() -> DailyFocus? {
        return getFocus(for: Date())
    }

    // Get the color for today's focus
    func getTodayColor() -> Color? {
        guard let todayFocus = getTodayFocus(),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == todayFocus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }

    // Helper to generate date key
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Save selections to UserDefaults
    private func saveSelections() {
        if let encoded = try? JSONEncoder().encode(selections) {
            userDefaults.set(encoded, forKey: selectionsKey)
        }
    }

    // Load selections from UserDefaults
    private func loadSelections() {
        if let data = userDefaults.data(forKey: selectionsKey),
           let decoded = try? JSONDecoder().decode([String: DailyFocus].self, from: data) {
            selections = decoded
        }
    }

    // Migrate data from App Group to standard UserDefaults (one-time migration)
    private func migrateIfNeeded() {
        // Check if migration has already been performed
        if userDefaults.bool(forKey: migrationKey) {
            return
        }

        // Try to load data from the old App Group location
        if let appGroupDefaults = UserDefaults(suiteName: "group.punchline.Pillars"),
           let oldData = appGroupDefaults.data(forKey: selectionsKey),
           let oldSelections = try? JSONDecoder().decode([String: DailyFocus].self, from: oldData),
           !oldSelections.isEmpty {

            // Check if we already have data in standard location
            let hasExistingData = userDefaults.data(forKey: selectionsKey) != nil

            // Only migrate if we don't have existing data (preserve existing data if present)
            if !hasExistingData {
                // Migrate data to standard UserDefaults
                if let encoded = try? JSONEncoder().encode(oldSelections) {
                    userDefaults.set(encoded, forKey: selectionsKey)
                    print("✅ Migrated \(oldSelections.count) focus selections from App Group to standard UserDefaults")
                }
            }
        }

        // Mark migration as complete
        userDefaults.set(true, forKey: migrationKey)
    }

    // MARK: - Todo List Management

    // Get todos for a specific date, including recurring instances
    func getTodos(for date: Date) -> [TodoItem] {
        let normalizedDate = DateUtils.appStartOfDay(for: date)
        let key = dateKey(for: normalizedDate)
        
        // Create recurring todo instances if needed
        createRecurringTodosIfNeeded(for: normalizedDate)
        
        return dailyTodos[key] ?? []
    }
    
    // Check and create recurring todo instances
    private func createRecurringTodosIfNeeded(for date: Date) {
        let calendar = Calendar.current
        let targetKey = dateKey(for: date)
        
        // Get existing todos for this date
        var existingTodos = dailyTodos[targetKey] ?? []
        let existingIds = Set(existingTodos.map { $0.id })
        
        // Check all dates that have todos
        for (storedKey, todos) in dailyTodos {
            guard let storedDate = dateFromKey(storedKey) else { continue }
            
            // Skip if stored date is after target date
            if storedDate > date { continue }
            
            for todo in todos where todo.recurrence != .none {
                let shouldCreate: Bool = {
                    switch todo.recurrence {
                    case .weekly:
                        // Same day of week
                        let storedWeekday = calendar.component(.weekday, from: storedDate)
                        let targetWeekday = calendar.component(.weekday, from: date)
                        return storedWeekday == targetWeekday && date > storedDate
                        
                    case .monthly:
                        // Same day of month
                        let storedDay = calendar.component(.day, from: storedDate)
                        let targetDay = calendar.component(.day, from: date)
                        return storedDay == targetDay && date > storedDate
                        
                    case .none:
                        return false
                    }
                }()
                
                if shouldCreate && !existingIds.contains(todo.id) {
                    // Create new instance for this date
                    var newTodo = todo
                    newTodo.isCompleted = false // Reset completion
                    newTodo.notificationId = nil // Will be rescheduled if needed
                    
                    // Schedule reminder if enabled
                    if newTodo.hasReminder, let reminderTime = newTodo.reminderTime {
                        let notificationId = NotificationManager.shared.scheduleTodoReminder(
                            todoId: newTodo.id.uuidString,
                            title: newTodo.text,
                            date: date,
                            reminderTime: reminderTime
                        )
                        newTodo.notificationId = notificationId
                    }
                    
                    // Add to existing todos for this date
                    existingTodos.append(newTodo)
                    dailyTodos[targetKey] = existingTodos
                    saveTodos()
                    
                    // Only create from the most recent occurrence
                    break
                }
            }
        }
    }
    
    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    // Set todos for a specific date
    func setTodos(for date: Date, todos: [TodoItem]) {
        let normalizedDate = DateUtils.appStartOfDay(for: date)
        let key = dateKey(for: normalizedDate)
        dailyTodos[key] = todos
        saveTodos()
    }

    // Add a todo for a specific date
    func addTodo(for date: Date, text: String) {
        var todos = getTodos(for: date)
        todos.append(TodoItem(text: text, isCompleted: false))
        setTodos(for: date, todos: todos)
    }

    // Toggle todo completion
    func toggleTodo(for date: Date, todoId: UUID) {
        var todos = getTodos(for: date)
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            todos[index].isCompleted.toggle()
            setTodos(for: date, todos: todos)
        }
    }

    // Update a todo
    func updateTodo(for date: Date, todo: TodoItem) {
        var todos = getTodos(for: date)
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            setTodos(for: date, todos: todos)
        }
    }

    // Delete a todo
    func deleteTodo(for date: Date, todoId: UUID) {
        var todos = getTodos(for: date)
        // Cancel notification if exists
        if let todo = todos.first(where: { $0.id == todoId }),
           let notificationId = todo.notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        todos.removeAll(where: { $0.id == todoId })
        setTodos(for: date, todos: todos)
    }

    // Save todos to UserDefaults
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(dailyTodos) {
            userDefaults.set(encoded, forKey: todosKey)
        }
    }

    // Load todos from UserDefaults
    private func loadTodos() {
        if let data = userDefaults.data(forKey: todosKey),
           let decoded = try? JSONDecoder().decode([String: [TodoItem]].self, from: data) {
            dailyTodos = decoded
        }
    }
}

// MARK: - TodoItem Model
enum TodoRecurrence: String, Codable, CaseIterable {
    case none = "None"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var recurrence: TodoRecurrence
    var hasReminder: Bool
    var reminderTime: Date?
    var notificationId: String?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        recurrence: TodoRecurrence = .none,
        hasReminder: Bool = false,
        reminderTime: Date? = nil,
        notificationId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.recurrence = recurrence
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
        self.notificationId = notificationId
    }
}
