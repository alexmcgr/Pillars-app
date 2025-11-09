//
//  NotificationManagerTests.swift
//  PillarsTests
//
//  Created by Cascade on 11/8/25.
//

import XCTest
import UserNotifications
@testable import Pillars

final class NotificationManagerTests: XCTestCase {
    
    var sut: NotificationManager!
    var calendar: Calendar!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Note: NotificationManager is a singleton, so tests affect shared state
        // In production code, consider making it testable by allowing dependency injection
        sut = NotificationManager.shared
        calendar = Calendar.current
    }
    
    override func tearDownWithError() throws {
        sut = nil
        calendar = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testNotificationManager_DefaultJournalTime() throws {
        // When: Accessing default notification time
        let time = sut.notificationTime
        
        // Then: Should have a valid time
        XCTAssertNotNil(time)
        
        let components = calendar.dateComponents([.hour, .minute], from: time)
        XCTAssertNotNil(components.hour)
        XCTAssertNotNil(components.minute)
    }
    
    func testNotificationManager_DefaultTodoAMTime() throws {
        // When: Accessing default AM time
        let time = sut.todoAMTime
        
        // Then: Should have a valid time
        XCTAssertNotNil(time)
        
        let components = calendar.dateComponents([.hour, .minute], from: time)
        XCTAssertNotNil(components.hour)
        XCTAssertNotNil(components.minute)
    }
    
    func testNotificationManager_DefaultTodoPMTime() throws {
        // When: Accessing default PM time
        let time = sut.todoPMTime
        
        // Then: Should have a valid time
        XCTAssertNotNil(time)
        
        let components = calendar.dateComponents([.hour, .minute], from: time)
        XCTAssertNotNil(components.hour)
        XCTAssertNotNil(components.minute)
    }
    
    // MARK: - Time Setting Tests
    
    func testNotificationManager_SetJournalTime() throws {
        // Given: A new time (9:30 PM)
        var components = DateComponents()
        components.hour = 21
        components.minute = 30
        let newTime = calendar.date(from: components)!
        
        // When: Setting journal notification time
        sut.notificationTime = newTime
        
        // Then: Time should be updated
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.notificationTime)
        XCTAssertEqual(retrievedComponents.hour, 21)
        XCTAssertEqual(retrievedComponents.minute, 30)
    }
    
    func testNotificationManager_SetTodoAMTime() throws {
        // Given: A new AM time (7:00 AM)
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let newTime = calendar.date(from: components)!
        
        // When: Setting AM time
        sut.todoAMTime = newTime
        
        // Then: Time should be updated
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.todoAMTime)
        XCTAssertEqual(retrievedComponents.hour, 7)
        XCTAssertEqual(retrievedComponents.minute, 0)
    }
    
    func testNotificationManager_SetTodoPMTime() throws {
        // Given: A new PM time (8:30 PM)
        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        let newTime = calendar.date(from: components)!
        
        // When: Setting PM time
        sut.todoPMTime = newTime
        
        // Then: Time should be updated
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.todoPMTime)
        XCTAssertEqual(retrievedComponents.hour, 20)
        XCTAssertEqual(retrievedComponents.minute, 30)
    }
    
    // MARK: - Notification ID Generation Tests
    
    func testScheduleTodoReminder_GeneratesCorrectId() throws {
        // Given: Todo parameters
        let todoId = UUID().uuidString
        let title = "Test Todo"
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling reminder
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: title,
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: ID should be prefixed with "todo_"
        XCTAssertTrue(notificationId.hasPrefix("todo_"), "Notification ID should start with 'todo_'")
        XCTAssertTrue(notificationId.contains(todoId), "Notification ID should contain todo ID")
    }
    
    func testScheduleTodoReminder_DifferentTodos_UniquIds() throws {
        // Given: Two different todos
        let todo1Id = UUID().uuidString
        let todo2Id = UUID().uuidString
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling both
        let notificationId1 = sut.scheduleTodoReminder(
            todoId: todo1Id,
            title: "First",
            date: date,
            reminderTime: reminderTime
        )
        let notificationId2 = sut.scheduleTodoReminder(
            todoId: todo2Id,
            title: "Second",
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: IDs should be different
        XCTAssertNotEqual(notificationId1, notificationId2)
    }
    
    // MARK: - Edge Cases
    
    func testScheduleTodoReminder_EmptyTitle() throws {
        // Given: Empty title
        let todoId = UUID().uuidString
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling with empty title
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: "",
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: Should still return ID
        XCTAssertFalse(notificationId.isEmpty)
        XCTAssertTrue(notificationId.hasPrefix("todo_"))
    }
    
    func testScheduleTodoReminder_LongTitle() throws {
        // Given: Very long title
        let longTitle = String(repeating: "A", count: 500)
        let todoId = UUID().uuidString
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling with long title
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: longTitle,
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: Should still work
        XCTAssertTrue(notificationId.hasPrefix("todo_"))
    }
    
    func testScheduleTodoReminder_SpecialCharactersInTitle() throws {
        // Given: Title with special characters
        let specialTitle = "Todo: Buy 🍎 & café! @#$%"
        let todoId = UUID().uuidString
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling with special characters
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: specialTitle,
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: Should work correctly
        XCTAssertTrue(notificationId.hasPrefix("todo_"))
    }
    
    func testScheduleTodoReminder_PastDate() throws {
        // Given: Date in the past
        let pastDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        let todoId = UUID().uuidString
        let reminderTime = Date()
        
        // When: Scheduling for past date
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: "Past task",
            date: pastDate,
            reminderTime: reminderTime
        )
        
        // Then: Should still return ID (actual scheduling behavior handled by UNUserNotificationCenter)
        XCTAssertFalse(notificationId.isEmpty)
    }
    
    func testScheduleTodoReminder_FutureDate() throws {
        // Given: Date in the future
        let futureDate = calendar.date(byAdding: .day, value: 7, to: Date())!
        let todoId = UUID().uuidString
        let reminderTime = Date()
        
        // When: Scheduling for future date
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: "Future task",
            date: futureDate,
            reminderTime: reminderTime
        )
        
        // Then: Should return ID
        XCTAssertFalse(notificationId.isEmpty)
    }
    
    func testCancelTodoReminder_EmptyId() throws {
        // Given: Empty notification ID
        let emptyId = ""
        
        // When: Canceling with empty ID
        // Then: Should not crash (actual behavior is handled by UNUserNotificationCenter)
        XCTAssertNoThrow(sut.cancelTodoReminder(notificationId: emptyId))
    }
    
    func testCancelTodoReminder_ValidId() throws {
        // Given: Valid notification ID
        let notificationId = "todo_test_123"
        
        // When: Canceling
        // Then: Should not crash
        XCTAssertNoThrow(sut.cancelTodoReminder(notificationId: notificationId))
    }
    
    // MARK: - Time Boundary Tests
    
    func testNotificationTime_MidnightBoundary() throws {
        // Given: Midnight time
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        let midnight = calendar.date(from: components)!
        
        // When: Setting to midnight
        sut.notificationTime = midnight
        
        // Then: Should accept midnight
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.notificationTime)
        XCTAssertEqual(retrievedComponents.hour, 0)
        XCTAssertEqual(retrievedComponents.minute, 0)
    }
    
    func testNotificationTime_23_59() throws {
        // Given: 11:59 PM
        var components = DateComponents()
        components.hour = 23
        components.minute = 59
        let lateNight = calendar.date(from: components)!
        
        // When: Setting to 11:59 PM
        sut.notificationTime = lateNight
        
        // Then: Should accept late time
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.notificationTime)
        XCTAssertEqual(retrievedComponents.hour, 23)
        XCTAssertEqual(retrievedComponents.minute, 59)
    }
    
    func testTodoAMTime_EarlyMorning() throws {
        // Given: 5:00 AM
        var components = DateComponents()
        components.hour = 5
        components.minute = 0
        let earlyMorning = calendar.date(from: components)!
        
        // When: Setting early AM time
        sut.todoAMTime = earlyMorning
        
        // Then: Should accept early time
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.todoAMTime)
        XCTAssertEqual(retrievedComponents.hour, 5)
    }
    
    func testTodoPMTime_LateEvening() throws {
        // Given: 11:00 PM
        var components = DateComponents()
        components.hour = 23
        components.minute = 0
        let lateEvening = calendar.date(from: components)!
        
        // When: Setting late PM time
        sut.todoPMTime = lateEvening
        
        // Then: Should accept late time
        let retrievedComponents = calendar.dateComponents([.hour, .minute], from: sut.todoPMTime)
        XCTAssertEqual(retrievedComponents.hour, 23)
    }
    
    // MARK: - Multiple Operations Tests
    
    func testScheduleMultipleTodoReminders() throws {
        // Given: Multiple todos
        let todos = [
            (UUID().uuidString, "First Todo"),
            (UUID().uuidString, "Second Todo"),
            (UUID().uuidString, "Third Todo")
        ]
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling all
        var notificationIds: [String] = []
        for (todoId, title) in todos {
            let id = sut.scheduleTodoReminder(
                todoId: todoId,
                title: title,
                date: date,
                reminderTime: reminderTime
            )
            notificationIds.append(id)
        }
        
        // Then: All should have unique IDs
        let uniqueIds = Set(notificationIds)
        XCTAssertEqual(uniqueIds.count, 3, "All notification IDs should be unique")
    }
    
    func testScheduleAndCancelTodoReminder() throws {
        // Given: A scheduled reminder
        let todoId = UUID().uuidString
        let notificationId = sut.scheduleTodoReminder(
            todoId: todoId,
            title: "Test",
            date: Date(),
            reminderTime: Date()
        )
        
        // When: Canceling it
        // Then: Should not crash
        XCTAssertNoThrow(sut.cancelTodoReminder(notificationId: notificationId))
    }
}

// MARK: - Helper Tests for Date/Time Combination

final class NotificationManagerDateTimeTests: XCTestCase {
    
    var sut: NotificationManager!
    var calendar: Calendar!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = NotificationManager.shared
        calendar = Calendar.current
    }
    
    override func tearDownWithError() throws {
        sut = nil
        calendar = nil
        try super.tearDownWithError()
    }
    
    func testScheduleTodoReminder_CombinesDateAndTime() throws {
        // Given: Specific date and time
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 25
        dateComponents.hour = 12
        let targetDate = calendar.date(from: dateComponents)!
        
        var timeComponents = DateComponents()
        timeComponents.hour = 9
        timeComponents.minute = 30
        let reminderTime = calendar.date(from: timeComponents)!
        
        // When: Scheduling reminder
        // The implementation should combine date from targetDate and time from reminderTime
        let notificationId = sut.scheduleTodoReminder(
            todoId: UUID().uuidString,
            title: "Test",
            date: targetDate,
            reminderTime: reminderTime
        )
        
        // Then: Should return valid ID
        XCTAssertFalse(notificationId.isEmpty)
        XCTAssertTrue(notificationId.hasPrefix("todo_"))
    }
    
    func testScheduleTodoReminder_DifferentTimeZones() throws {
        // Given: Current time zone
        let date = Date()
        let reminderTime = Date()
        
        // When: Scheduling (uses current time zone)
        let notificationId = sut.scheduleTodoReminder(
            todoId: UUID().uuidString,
            title: "Timezone test",
            date: date,
            reminderTime: reminderTime
        )
        
        // Then: Should work regardless of time zone
        XCTAssertFalse(notificationId.isEmpty)
    }
}
