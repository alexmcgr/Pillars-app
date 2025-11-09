//
//  TodoItemTests.swift
//  PillarsTests
//
//  Created by Cascade on 11/8/25.
//

import XCTest
@testable import Pillars

final class TodoItemTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testTodoItem_DefaultInitialization() throws {
        // When: Creating a TodoItem with defaults
        let todo = TodoItem(text: "Test Todo", isCompleted: false)
        
        // Then: Should have correct default values
        XCTAssertNotNil(todo.id)
        XCTAssertEqual(todo.text, "Test Todo")
        XCTAssertFalse(todo.isCompleted)
        XCTAssertEqual(todo.recurrence, .none)
        XCTAssertFalse(todo.hasReminder)
        XCTAssertNil(todo.reminderTime)
        XCTAssertNil(todo.notificationId)
    }
    
    func testTodoItem_FullInitialization() throws {
        // Given: All properties
        let id = UUID()
        let reminderTime = Date()
        let notificationId = "test_notification_123"
        
        // When: Creating fully initialized TodoItem
        let todo = TodoItem(
            id: id,
            text: "Complete Todo",
            isCompleted: true,
            recurrence: .weekly,
            hasReminder: true,
            reminderTime: reminderTime,
            notificationId: notificationId
        )
        
        // Then: All properties should be set
        XCTAssertEqual(todo.id, id)
        XCTAssertEqual(todo.text, "Complete Todo")
        XCTAssertTrue(todo.isCompleted)
        XCTAssertEqual(todo.recurrence, .weekly)
        XCTAssertTrue(todo.hasReminder)
        XCTAssertEqual(todo.reminderTime, reminderTime)
        XCTAssertEqual(todo.notificationId, notificationId)
    }
    
    func testTodoItem_EmptyText() throws {
        // When: Creating with empty text
        let todo = TodoItem(text: "", isCompleted: false)
        
        // Then: Should accept empty text
        XCTAssertEqual(todo.text, "")
    }
    
    func testTodoItem_LongText() throws {
        // Given: Very long text
        let longText = String(repeating: "A", count: 5000)
        
        // When: Creating with long text
        let todo = TodoItem(text: longText, isCompleted: false)
        
        // Then: Should accept long text
        XCTAssertEqual(todo.text.count, 5000)
    }
    
    func testTodoItem_SpecialCharacters() throws {
        // Given: Text with special characters
        let specialText = "Todo: Buy 🍎🍊🍋 & café! @#$% (important)"
        
        // When: Creating with special text
        let todo = TodoItem(text: specialText, isCompleted: false)
        
        // Then: Should preserve special characters
        XCTAssertEqual(todo.text, specialText)
    }
    
    func testTodoItem_UniqueIds() throws {
        // When: Creating multiple TodoItems
        let todo1 = TodoItem(text: "First", isCompleted: false)
        let todo2 = TodoItem(text: "Second", isCompleted: false)
        let todo3 = TodoItem(text: "Third", isCompleted: false)
        
        // Then: IDs should be unique
        XCTAssertNotEqual(todo1.id, todo2.id)
        XCTAssertNotEqual(todo2.id, todo3.id)
        XCTAssertNotEqual(todo1.id, todo3.id)
    }
    
    // MARK: - Recurrence Tests
    
    func testTodoItem_RecurrenceNone() throws {
        // When: Creating non-recurring todo
        let todo = TodoItem(text: "One-time task", isCompleted: false, recurrence: .none)
        
        // Then: Recurrence should be none
        XCTAssertEqual(todo.recurrence, .none)
    }
    
    func testTodoItem_RecurrenceWeekly() throws {
        // When: Creating weekly recurring todo
        let todo = TodoItem(text: "Weekly task", isCompleted: false, recurrence: .weekly)
        
        // Then: Recurrence should be weekly
        XCTAssertEqual(todo.recurrence, .weekly)
    }
    
    func testTodoItem_RecurrenceMonthly() throws {
        // When: Creating monthly recurring todo
        let todo = TodoItem(text: "Monthly task", isCompleted: false, recurrence: .monthly)
        
        // Then: Recurrence should be monthly
        XCTAssertEqual(todo.recurrence, .monthly)
    }
    
    // MARK: - Reminder Tests
    
    func testTodoItem_NoReminder() throws {
        // When: Creating todo without reminder
        let todo = TodoItem(text: "Task", isCompleted: false, hasReminder: false)
        
        // Then: Should have no reminder
        XCTAssertFalse(todo.hasReminder)
        XCTAssertNil(todo.reminderTime)
        XCTAssertNil(todo.notificationId)
    }
    
    func testTodoItem_WithReminder() throws {
        // Given: Reminder time
        let reminderTime = Date()
        
        // When: Creating todo with reminder
        let todo = TodoItem(
            text: "Important task",
            isCompleted: false,
            hasReminder: true,
            reminderTime: reminderTime
        )
        
        // Then: Reminder should be set
        XCTAssertTrue(todo.hasReminder)
        XCTAssertEqual(todo.reminderTime, reminderTime)
    }
    
    func testTodoItem_ReminderInconsistency_HasReminderTrueButNoTime() throws {
        // When: Creating with hasReminder=true but no time (edge case)
        let todo = TodoItem(
            text: "Task",
            isCompleted: false,
            hasReminder: true,
            reminderTime: nil
        )
        
        // Then: Should allow inconsistent state (business logic handles validation)
        XCTAssertTrue(todo.hasReminder)
        XCTAssertNil(todo.reminderTime)
    }
    
    func testTodoItem_ReminderWithNotificationId() throws {
        // Given: Reminder with notification ID
        let reminderTime = Date()
        let notificationId = "reminder_xyz"
        
        // When: Creating with full reminder info
        let todo = TodoItem(
            text: "Notified task",
            isCompleted: false,
            hasReminder: true,
            reminderTime: reminderTime,
            notificationId: notificationId
        )
        
        // Then: All reminder info should be set
        XCTAssertTrue(todo.hasReminder)
        XCTAssertNotNil(todo.reminderTime)
        XCTAssertEqual(todo.notificationId, notificationId)
    }
    
    // MARK: - Mutation Tests
    
    func testTodoItem_MutableText() throws {
        // Given: A todo
        var todo = TodoItem(text: "Original", isCompleted: false)
        
        // When: Changing text
        todo.text = "Modified"
        
        // Then: Text should be updated
        XCTAssertEqual(todo.text, "Modified")
    }
    
    func testTodoItem_MutableCompletionStatus() throws {
        // Given: An incomplete todo
        var todo = TodoItem(text: "Task", isCompleted: false)
        
        // When: Completing the todo
        todo.isCompleted = true
        
        // Then: Should be completed
        XCTAssertTrue(todo.isCompleted)
    }
    
    func testTodoItem_MutableRecurrence() throws {
        // Given: A non-recurring todo
        var todo = TodoItem(text: "Task", isCompleted: false)
        
        // When: Making it weekly
        todo.recurrence = .weekly
        
        // Then: Recurrence should be updated
        XCTAssertEqual(todo.recurrence, .weekly)
    }
    
    func testTodoItem_MutableReminder() throws {
        // Given: A todo without reminder
        var todo = TodoItem(text: "Task", isCompleted: false)
        
        // When: Adding reminder
        todo.hasReminder = true
        todo.reminderTime = Date()
        todo.notificationId = "new_notification"
        
        // Then: Reminder should be set
        XCTAssertTrue(todo.hasReminder)
        XCTAssertNotNil(todo.reminderTime)
        XCTAssertEqual(todo.notificationId, "new_notification")
    }
    
    // MARK: - Combined Feature Tests
    
    func testTodoItem_RecurringWithReminder() throws {
        // Given: Weekly recurring todo with reminder
        let reminderTime = Date()
        
        // When: Creating combined todo
        let todo = TodoItem(
            text: "Weekly meeting",
            isCompleted: false,
            recurrence: .weekly,
            hasReminder: true,
            reminderTime: reminderTime,
            notificationId: "weekly_meeting_123"
        )
        
        // Then: Both features should work
        XCTAssertEqual(todo.recurrence, .weekly)
        XCTAssertTrue(todo.hasReminder)
        XCTAssertNotNil(todo.reminderTime)
        XCTAssertNotNil(todo.notificationId)
    }
    
    func testTodoItem_CompletedRecurringTodo() throws {
        // When: Creating completed recurring todo
        let todo = TodoItem(
            text: "Completed weekly task",
            isCompleted: true,
            recurrence: .weekly
        )
        
        // Then: Can be both completed and recurring
        XCTAssertTrue(todo.isCompleted)
        XCTAssertEqual(todo.recurrence, .weekly)
    }
}

// MARK: - TodoRecurrence Tests

final class TodoRecurrenceTests: XCTestCase {
    
    func testTodoRecurrence_AllCases() throws {
        // When: Getting all cases
        let allCases = TodoRecurrence.allCases
        
        // Then: Should have all three values
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.weekly))
        XCTAssertTrue(allCases.contains(.monthly))
    }
    
    func testTodoRecurrence_RawValues() throws {
        // Then: Raw values should match enum cases
        XCTAssertEqual(TodoRecurrence.none.rawValue, "None")
        XCTAssertEqual(TodoRecurrence.weekly.rawValue, "Weekly")
        XCTAssertEqual(TodoRecurrence.monthly.rawValue, "Monthly")
    }
    
    func testTodoRecurrence_InitFromRawValue() throws {
        // When: Initializing from raw values
        let none = TodoRecurrence(rawValue: "None")
        let weekly = TodoRecurrence(rawValue: "Weekly")
        let monthly = TodoRecurrence(rawValue: "Monthly")
        let invalid = TodoRecurrence(rawValue: "Invalid")
        
        // Then: Valid values should succeed, invalid should fail
        XCTAssertNotNil(none, "Valid raw value 'None' should succeed")
        XCTAssertEqual(none, .none)
        XCTAssertNotNil(weekly, "Valid raw value 'Weekly' should succeed")
        XCTAssertEqual(weekly, .weekly)
        XCTAssertNotNil(monthly, "Valid raw value 'Monthly' should succeed")
        XCTAssertEqual(monthly, .monthly)
        XCTAssertNil(invalid, "Invalid raw value should return nil")
    }
    
    func testTodoRecurrence_CaseComparison() throws {
        // When: Comparing cases
        let none1 = TodoRecurrence.none
        let none2 = TodoRecurrence.none
        let weekly = TodoRecurrence.weekly
        
        // Then: Same cases should be equal
        XCTAssertEqual(none1, none2)
        XCTAssertNotEqual(none1, weekly)
    }
    
    func testTodoRecurrence_Codable() throws {
        // Given: TodoRecurrence values
        let recurrences: [TodoRecurrence] = [.none, .weekly, .monthly]
        
        for recurrence in recurrences {
            // When: Encoding and decoding
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            let encoded = try encoder.encode(recurrence)
            let decoded = try decoder.decode(TodoRecurrence.self, from: encoded)
            
            // Then: Should preserve value
            XCTAssertEqual(decoded, recurrence)
        }
    }
}
