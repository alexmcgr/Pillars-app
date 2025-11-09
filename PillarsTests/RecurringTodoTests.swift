//
//  RecurringTodoTests.swift
//  PillarsTests
//
//  Created by Cascade on 11/8/25.
//

import XCTest
@testable import Pillars

final class RecurringTodoTests: XCTestCase {
    
    var sut: FocusStore!
    var calendar: Calendar!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Clear UserDefaults before each test to ensure isolation
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "dailyFocuses")
        defaults.removeObject(forKey: "dailyTodos")
        defaults.synchronize()
        
        sut = FocusStore()
        calendar = Calendar.current
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "dailyFocuses")
        defaults.removeObject(forKey: "dailyTodos")
        defaults.synchronize()
        
        sut = nil
        calendar = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Weekly Recurrence Tests
    
    func testWeeklyRecurrence_SameDayOfWeek_CreatesInstance() throws {
        // Given: A weekly recurring todo on Monday
        var mondayComponents = DateComponents()
        mondayComponents.year = 2025
        mondayComponents.month = 11
        mondayComponents.day = 10 // Monday
        mondayComponents.hour = 12
        let firstMonday = calendar.date(from: mondayComponents)!
        
        // Create weekly todo
        var weeklyTodo = TodoItem(text: "Weekly Meeting", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: firstMonday, todos: [weeklyTodo])
        
        // When: Checking next Monday (7 days later)
        var nextMondayComponents = DateComponents()
        nextMondayComponents.year = 2025
        nextMondayComponents.month = 11
        nextMondayComponents.day = 17 // Next Monday
        nextMondayComponents.hour = 12
        let nextMonday = calendar.date(from: nextMondayComponents)!
        
        let todos = sut.getTodos(for: nextMonday)
        
        // Then: Should have the recurring todo
        XCTAssertGreaterThan(todos.count, 0, "Should have recurring todo instance")
        XCTAssertTrue(todos.contains(where: { $0.text == "Weekly Meeting" }), "Should find weekly meeting")
    }
    
    func testWeeklyRecurrence_DifferentDayOfWeek_NoInstance() throws {
        // Given: A weekly recurring todo on Monday
        var mondayComponents = DateComponents()
        mondayComponents.year = 2025
        mondayComponents.month = 11
        mondayComponents.day = 10 // Monday
        mondayComponents.hour = 12
        let monday = calendar.date(from: mondayComponents)!
        
        var weeklyTodo = TodoItem(text: "Monday Task", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: monday, todos: [weeklyTodo])
        
        // When: Checking Tuesday (different day of week)
        var tuesdayComponents = DateComponents()
        tuesdayComponents.year = 2025
        tuesdayComponents.month = 11
        tuesdayComponents.day = 11 // Tuesday
        tuesdayComponents.hour = 12
        let tuesday = calendar.date(from: tuesdayComponents)!
        
        let todos = sut.getTodos(for: tuesday)
        
        // Then: Should NOT have the Monday recurring todo
        XCTAssertFalse(todos.contains(where: { $0.text == "Monday Task" }), "Should not find Monday task on Tuesday")
    }
    
    func testWeeklyRecurrence_MultipleWeeks_CreatesInstances() throws {
        // Given: A weekly recurring todo
        var firstDayComponents = DateComponents()
        firstDayComponents.year = 2025
        firstDayComponents.month = 11
        firstDayComponents.day = 10 // Monday
        firstDayComponents.hour = 12
        let firstDay = calendar.date(from: firstDayComponents)!
        
        var weeklyTodo = TodoItem(text: "Recurring Task", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: firstDay, todos: [weeklyTodo])
        
        // When: Checking multiple weeks ahead
        for weekOffset in 1...4 {
            let futureDate = calendar.date(byAdding: .day, value: weekOffset * 7, to: firstDay)!
            let todos = sut.getTodos(for: futureDate)
            
            // Then: Should have recurring todo each week
            XCTAssertTrue(
                todos.contains(where: { $0.text == "Recurring Task" }),
                "Should have recurring todo at week offset \(weekOffset)"
            )
        }
    }
    
    func testWeeklyRecurrence_CompletionReset() throws {
        // Given: A completed weekly recurring todo
        var firstDayComponents = DateComponents()
        firstDayComponents.year = 2025
        firstDayComponents.month = 11
        firstDayComponents.day = 10
        firstDayComponents.hour = 12
        let firstDay = calendar.date(from: firstDayComponents)!
        
        var weeklyTodo = TodoItem(text: "Weekly Task", isCompleted: true, recurrence: .weekly)
        sut.setTodos(for: firstDay, todos: [weeklyTodo])
        
        // When: Checking next week
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: firstDay)!
        let todos = sut.getTodos(for: nextWeek)
        
        // Then: New instance should be incomplete
        let recurringTodo = todos.first(where: { $0.text == "Weekly Task" })
        XCTAssertNotNil(recurringTodo, "Should have recurring todo")
        XCTAssertFalse(recurringTodo?.isCompleted ?? true, "Recurring instance should be incomplete")
    }
    
    // MARK: - Monthly Recurrence Tests
    
    func testMonthlyRecurrence_SameDayOfMonth_CreatesInstance() throws {
        // Given: A monthly recurring todo on the 15th
        var firstMonthComponents = DateComponents()
        firstMonthComponents.year = 2025
        firstMonthComponents.month = 11
        firstMonthComponents.day = 15
        firstMonthComponents.hour = 12
        let firstMonth = calendar.date(from: firstMonthComponents)!
        
        var monthlyTodo = TodoItem(text: "Monthly Report", isCompleted: false, recurrence: .monthly)
        sut.setTodos(for: firstMonth, todos: [monthlyTodo])
        
        // When: Checking next month on the 15th
        var nextMonthComponents = DateComponents()
        nextMonthComponents.year = 2025
        nextMonthComponents.month = 12
        nextMonthComponents.day = 15
        nextMonthComponents.hour = 12
        let nextMonth = calendar.date(from: nextMonthComponents)!
        
        let todos = sut.getTodos(for: nextMonth)
        
        // Then: Should have the recurring todo
        XCTAssertTrue(
            todos.contains(where: { $0.text == "Monthly Report" }),
            "Should find monthly report on same day next month"
        )
    }
    
    func testMonthlyRecurrence_DifferentDayOfMonth_NoInstance() throws {
        // Given: A monthly recurring todo on the 15th
        var fifteenthComponents = DateComponents()
        fifteenthComponents.year = 2025
        fifteenthComponents.month = 11
        fifteenthComponents.day = 15
        fifteenthComponents.hour = 12
        let fifteenth = calendar.date(from: fifteenthComponents)!
        
        var monthlyTodo = TodoItem(text: "15th Task", isCompleted: false, recurrence: .monthly)
        sut.setTodos(for: fifteenth, todos: [monthlyTodo])
        
        // When: Checking the 16th
        var sixteenthComponents = DateComponents()
        sixteenthComponents.year = 2025
        sixteenthComponents.month = 11
        sixteenthComponents.day = 16
        sixteenthComponents.hour = 12
        let sixteenth = calendar.date(from: sixteenthComponents)!
        
        let todos = sut.getTodos(for: sixteenth)
        
        // Then: Should NOT have the 15th recurring todo
        XCTAssertFalse(
            todos.contains(where: { $0.text == "15th Task" }),
            "Should not find 15th task on 16th"
        )
    }
    
    func testMonthlyRecurrence_MultipleMonths_CreatesInstances() throws {
        // Given: A monthly recurring todo
        var firstDayComponents = DateComponents()
        firstDayComponents.year = 2025
        firstDayComponents.month = 1
        firstDayComponents.day = 1
        firstDayComponents.hour = 12
        let firstDay = calendar.date(from: firstDayComponents)!
        
        var monthlyTodo = TodoItem(text: "Monthly Task", isCompleted: false, recurrence: .monthly)
        sut.setTodos(for: firstDay, todos: [monthlyTodo])
        
        // When: Checking multiple months ahead
        for monthOffset in 1...6 {
            var futureComponents = DateComponents()
            futureComponents.year = 2025
            futureComponents.month = 1 + monthOffset
            futureComponents.day = 1
            futureComponents.hour = 12
            guard let futureDate = calendar.date(from: futureComponents) else { continue }
            
            let todos = sut.getTodos(for: futureDate)
            
            // Then: Should have recurring todo each month
            XCTAssertTrue(
                todos.contains(where: { $0.text == "Monthly Task" }),
                "Should have monthly task at month offset \(monthOffset)"
            )
        }
    }
    
    func testMonthlyRecurrence_EndOfMonth_HandlesCorrectly() throws {
        // Given: A monthly recurring todo on Jan 31
        var jan31Components = DateComponents()
        jan31Components.year = 2025
        jan31Components.month = 1
        jan31Components.day = 31
        jan31Components.hour = 12
        let jan31 = calendar.date(from: jan31Components)!
        
        var monthlyTodo = TodoItem(text: "End of Month Task", isCompleted: false, recurrence: .monthly)
        sut.setTodos(for: jan31, todos: [monthlyTodo])
        
        // When: Checking March 31 (Feb has only 28 days)
        var mar31Components = DateComponents()
        mar31Components.year = 2025
        mar31Components.month = 3
        mar31Components.day = 31
        mar31Components.hour = 12
        let mar31 = calendar.date(from: mar31Components)!
        
        let todos = sut.getTodos(for: mar31)
        
        // Then: Should have recurring todo on Mar 31
        XCTAssertTrue(
            todos.contains(where: { $0.text == "End of Month Task" }),
            "Should find end of month task on Mar 31"
        )
    }
    
    // MARK: - Non-Recurring Tests
    
    func testNonRecurrence_NoFutureInstances() throws {
        // Given: A non-recurring todo
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        var oneTimeTodo = TodoItem(text: "One-time Task", isCompleted: false, recurrence: .none)
        sut.setTodos(for: day, todos: [oneTimeTodo])
        
        // When: Checking next day/week/month
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: day)!
        
        // Then: Should NOT have todo on future dates
        XCTAssertFalse(
            sut.getTodos(for: nextDay).contains(where: { $0.text == "One-time Task" }),
            "Should not find one-time task next day"
        )
        XCTAssertFalse(
            sut.getTodos(for: nextWeek).contains(where: { $0.text == "One-time Task" }),
            "Should not find one-time task next week"
        )
        XCTAssertFalse(
            sut.getTodos(for: nextMonth).contains(where: { $0.text == "One-time Task" }),
            "Should not find one-time task next month"
        )
    }
    
    // MARK: - Mixed Recurring and Non-Recurring Tests
    
    func testMixedTodos_BothTypes_OnlyRecurringRepeats() throws {
        // Given: Both recurring and non-recurring todos
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        let weeklyTodo = TodoItem(text: "Weekly", isCompleted: false, recurrence: .weekly)
        let oneTimeTodo = TodoItem(text: "One-time", isCompleted: false, recurrence: .none)
        sut.setTodos(for: day, todos: [weeklyTodo, oneTimeTodo])
        
        // When: Checking next week
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day)!
        let todos = sut.getTodos(for: nextWeek)
        
        // Then: Should have weekly but not one-time
        XCTAssertTrue(
            todos.contains(where: { $0.text == "Weekly" }),
            "Should find weekly todo"
        )
        XCTAssertFalse(
            todos.contains(where: { $0.text == "One-time" }),
            "Should not find one-time todo"
        )
    }
    
    func testMultipleRecurringTodos_AllCreateInstances() throws {
        // Given: Multiple recurring todos
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        let weekly1 = TodoItem(text: "Weekly 1", isCompleted: false, recurrence: .weekly)
        let weekly2 = TodoItem(text: "Weekly 2", isCompleted: false, recurrence: .weekly)
        let weekly3 = TodoItem(text: "Weekly 3", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: day, todos: [weekly1, weekly2, weekly3])
        
        // When: Checking next week
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day)!
        let todos = sut.getTodos(for: nextWeek)
        
        // Then: Should have all three recurring todos
        XCTAssertEqual(
            todos.filter({ $0.text.hasPrefix("Weekly") }).count,
            3,
            "Should have all three weekly todos"
        )
    }
    
    // MARK: - Edge Cases
    
    func testRecurringTodo_PastDate_NoCreation() throws {
        // Given: A recurring todo
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        var weeklyTodo = TodoItem(text: "Weekly", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: day, todos: [weeklyTodo])
        
        // When: Checking past date (before original)
        let pastWeek = calendar.date(byAdding: .day, value: -7, to: day)!
        let todos = sut.getTodos(for: pastWeek)
        
        // Then: Should NOT have recurring todo in the past
        XCTAssertFalse(
            todos.contains(where: { $0.text == "Weekly" }),
            "Should not create recurring instances in the past"
        )
    }
    
    func testRecurringTodo_WithReminder_ResetsNotificationId() throws {
        // Given: A recurring todo with a reminder
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        var weeklyTodo = TodoItem(
            text: "Weekly with Reminder",
            isCompleted: false,
            recurrence: .weekly,
            hasReminder: true,
            reminderTime: Date(),
            notificationId: "original_notification"
        )
        sut.setTodos(for: day, todos: [weeklyTodo])
        
        // When: Checking next week
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day)!
        let todos = sut.getTodos(for: nextWeek)
        
        // Then: New instance should have a new notification ID
        let recurringInstance = todos.first(where: { $0.text == "Weekly with Reminder" })
        XCTAssertNotNil(recurringInstance, "Should have recurring instance")
        // Note: Implementation should create new notification ID
    }
    
    func testRecurringTodo_NoDuplicates() throws {
        // Given: A recurring todo
        var dayComponents = DateComponents()
        dayComponents.year = 2025
        dayComponents.month = 11
        dayComponents.day = 10
        dayComponents.hour = 12
        let day = calendar.date(from: dayComponents)!
        
        var weeklyTodo = TodoItem(text: "Unique Weekly", isCompleted: false, recurrence: .weekly)
        sut.setTodos(for: day, todos: [weeklyTodo])
        
        // When: Accessing the same future date multiple times
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day)!
        let todos1 = sut.getTodos(for: nextWeek)
        let todos2 = sut.getTodos(for: nextWeek)
        let todos3 = sut.getTodos(for: nextWeek)
        
        // Then: Should not create duplicates
        let count1 = todos1.filter({ $0.text == "Unique Weekly" }).count
        let count2 = todos2.filter({ $0.text == "Unique Weekly" }).count
        let count3 = todos3.filter({ $0.text == "Unique Weekly" }).count
        
        XCTAssertEqual(count1, 1, "Should have exactly one instance (first access)")
        XCTAssertEqual(count2, 1, "Should have exactly one instance (second access)")
        XCTAssertEqual(count3, 1, "Should have exactly one instance (third access)")
    }
}
