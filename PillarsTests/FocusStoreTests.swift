//
//  FocusStoreTests.swift
//  PillarsTests
//
//  Created by Cascade on 11/8/25.
//

import XCTest
@testable import Pillars

final class FocusStoreTests: XCTestCase {
    
    var sut: FocusStore!
    var testDate: Date!
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
        
        // Use a fixed date for consistent testing (Nov 8, 2025 at noon)
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 12
        components.minute = 0
        testDate = calendar.date(from: components)!
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "dailyFocuses")
        defaults.removeObject(forKey: "dailyTodos")
        defaults.synchronize()
        
        sut = nil
        testDate = nil
        calendar = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Todo Management Tests
    
    func testAddTodo_CreatesNewTodo() throws {
        // Given: Empty todos for test date
        let initialTodos = sut.getTodos(for: testDate)
        XCTAssertEqual(initialTodos.count, 0, "Should start with no todos")
        
        // When: Adding a new todo
        sut.addTodo(for: testDate, text: "Test Todo")
        
        // Then: Todo should be added
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 1, "Should have one todo")
        XCTAssertEqual(todos.first?.text, "Test Todo")
        XCTAssertFalse(todos.first?.isCompleted ?? true)
    }
    
    func testAddTodo_WithEmptyText_CreatesEmptyTodo() throws {
        // Given: Empty text
        let emptyText = ""
        
        // When: Adding todo with empty text
        sut.addTodo(for: testDate, text: emptyText)
        
        // Then: Todo should still be created
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 1)
        XCTAssertEqual(todos.first?.text, "")
    }
    
    func testAddTodo_MultipleTodos_MaintainsOrder() throws {
        // Given: Multiple todos
        let todoTexts = ["First", "Second", "Third"]
        
        // When: Adding todos in order
        for text in todoTexts {
            sut.addTodo(for: testDate, text: text)
        }
        
        // Then: Order should be preserved
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 3)
        XCTAssertEqual(todos[0].text, "First")
        XCTAssertEqual(todos[1].text, "Second")
        XCTAssertEqual(todos[2].text, "Third")
    }
    
    func testGetTodos_DifferentDates_ReturnsSeparateLists() throws {
        // Given: Todos on different dates
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: testDate)!
        sut.addTodo(for: testDate, text: "Today's todo")
        sut.addTodo(for: tomorrow, text: "Tomorrow's todo")
        
        // When: Getting todos for each date
        let todayTodos = sut.getTodos(for: testDate)
        let tomorrowTodos = sut.getTodos(for: tomorrow)
        
        // Then: Should get separate lists
        XCTAssertEqual(todayTodos.count, 1)
        XCTAssertEqual(tomorrowTodos.count, 1)
        XCTAssertEqual(todayTodos.first?.text, "Today's todo")
        XCTAssertEqual(tomorrowTodos.first?.text, "Tomorrow's todo")
    }
    
    func testToggleTodo_CompletesIncompleteTodo() throws {
        // Given: An incomplete todo
        sut.addTodo(for: testDate, text: "Test Todo")
        let todoId = sut.getTodos(for: testDate).first!.id
        
        // When: Toggling the todo
        sut.toggleTodo(for: testDate, todoId: todoId)
        
        // Then: Todo should be completed
        let todos = sut.getTodos(for: testDate)
        XCTAssertTrue(todos.first?.isCompleted ?? false)
    }
    
    func testToggleTodo_UncompletesCompletedTodo() throws {
        // Given: A completed todo
        sut.addTodo(for: testDate, text: "Test Todo")
        let todoId = sut.getTodos(for: testDate).first!.id
        sut.toggleTodo(for: testDate, todoId: todoId) // Complete it
        
        // When: Toggling again
        sut.toggleTodo(for: testDate, todoId: todoId)
        
        // Then: Todo should be incomplete
        let todos = sut.getTodos(for: testDate)
        XCTAssertFalse(todos.first?.isCompleted ?? true)
    }
    
    func testToggleTodo_InvalidId_NoChange() throws {
        // Given: A todo with known ID
        sut.addTodo(for: testDate, text: "Test Todo")
        let initialTodos = sut.getTodos(for: testDate)
        
        // When: Toggling with invalid ID
        sut.toggleTodo(for: testDate, todoId: UUID())
        
        // Then: No change should occur
        let finalTodos = sut.getTodos(for: testDate)
        XCTAssertEqual(initialTodos.first?.isCompleted, finalTodos.first?.isCompleted)
    }
    
    func testUpdateTodo_ModifiesExistingTodo() throws {
        // Given: An existing todo
        sut.addTodo(for: testDate, text: "Original Text")
        let originalTodo = sut.getTodos(for: testDate).first!
        
        // When: Updating the todo
        var updatedTodo = originalTodo
        updatedTodo.text = "Updated Text"
        updatedTodo.hasReminder = true
        sut.updateTodo(for: testDate, todo: updatedTodo)
        
        // Then: Todo should be updated
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.first?.text, "Updated Text")
        XCTAssertTrue(todos.first?.hasReminder ?? false)
    }
    
    func testUpdateTodo_PreservesId() throws {
        // Given: An existing todo
        sut.addTodo(for: testDate, text: "Original")
        let originalId = sut.getTodos(for: testDate).first!.id
        
        // When: Updating the todo
        var updatedTodo = sut.getTodos(for: testDate).first!
        updatedTodo.text = "Modified"
        sut.updateTodo(for: testDate, todo: updatedTodo)
        
        // Then: ID should remain the same
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.first?.id, originalId)
    }
    
    func testDeleteTodo_RemovesTodo() throws {
        // Given: Multiple todos
        sut.addTodo(for: testDate, text: "First")
        sut.addTodo(for: testDate, text: "Second")
        sut.addTodo(for: testDate, text: "Third")
        let todoToDelete = sut.getTodos(for: testDate)[1] // Middle one
        
        // When: Deleting a todo
        sut.deleteTodo(for: testDate, todoId: todoToDelete.id)
        
        // Then: Todo should be removed
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 2)
        XCTAssertFalse(todos.contains(where: { $0.id == todoToDelete.id }))
    }
    
    func testDeleteTodo_InvalidId_NoChange() throws {
        // Given: Todos
        sut.addTodo(for: testDate, text: "First")
        sut.addTodo(for: testDate, text: "Second")
        let initialCount = sut.getTodos(for: testDate).count
        
        // When: Deleting with invalid ID
        sut.deleteTodo(for: testDate, todoId: UUID())
        
        // Then: No change
        let finalCount = sut.getTodos(for: testDate).count
        XCTAssertEqual(initialCount, finalCount)
    }
    
    func testSetTodos_ReplacesExistingTodos() throws {
        // Given: Existing todos
        sut.addTodo(for: testDate, text: "Old Todo")
        
        // When: Setting new todos list
        let newTodos = [
            TodoItem(text: "New Todo 1", isCompleted: false),
            TodoItem(text: "New Todo 2", isCompleted: true)
        ]
        sut.setTodos(for: testDate, todos: newTodos)
        
        // Then: Should have new todos
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 2)
        XCTAssertEqual(todos[0].text, "New Todo 1")
        XCTAssertEqual(todos[1].text, "New Todo 2")
        XCTAssertTrue(todos[1].isCompleted)
    }
    
    func testSetTodos_EmptyList_ClearsTodos() throws {
        // Given: Existing todos
        sut.addTodo(for: testDate, text: "Todo 1")
        sut.addTodo(for: testDate, text: "Todo 2")
        
        // When: Setting empty list
        sut.setTodos(for: testDate, todos: [])
        
        // Then: Should have no todos
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.count, 0)
    }
    
    // MARK: - Focus Management Tests
    
    func testSetFocus_CreatesFocus() throws {
        // Given: No focus for date
        XCTAssertNil(sut.getFocus(for: testDate))
        
        // When: Setting focus
        sut.setFocus(for: testDate, choiceId: 0)
        
        // Then: Focus should be set
        let focus = sut.getFocus(for: testDate)
        XCTAssertNotNil(focus)
        XCTAssertEqual(focus?.choiceId, 0)
    }
    
    func testSetFocus_UpdatesExistingFocus() throws {
        // Given: Existing focus
        sut.setFocus(for: testDate, choiceId: 0)
        
        // When: Changing focus
        sut.setFocus(for: testDate, choiceId: 2)
        
        // Then: Focus should be updated
        let focus = sut.getFocus(for: testDate)
        XCTAssertEqual(focus?.choiceId, 2)
    }
    
    func testGetFocus_NoFocus_ReturnsNil() throws {
        // When: Getting focus for date with no focus
        let focus = sut.getFocus(for: testDate)
        
        // Then: Should be nil
        XCTAssertNil(focus)
    }
    
    func testGetTodayFocus_ReturnsCurrentDayFocus() throws {
        // Given: Focus set for today
        let today = DateUtils.appToday()
        sut.setFocus(for: today, choiceId: 1)
        
        // When: Getting today's focus
        let focus = sut.getTodayFocus()
        
        // Then: Should return today's focus
        XCTAssertNotNil(focus)
        XCTAssertEqual(focus?.choiceId, 1)
    }
    
    // MARK: - Journal Entry Tests
    
    func testSetJournalEntry_CreatesEntry() throws {
        // Given: No journal entry
        XCTAssertNil(sut.getJournalEntry(for: testDate))
        
        // When: Setting journal entry
        let entry = "Today was a great day!"
        sut.setJournalEntry(for: testDate, entry: entry)
        
        // Then: Entry should be set
        let retrievedEntry = sut.getJournalEntry(for: testDate)
        XCTAssertEqual(retrievedEntry, entry)
    }
    
    func testSetJournalEntry_UpdatesExistingEntry() throws {
        // Given: Existing journal entry
        sut.setJournalEntry(for: testDate, entry: "First entry")
        
        // When: Updating entry
        sut.setJournalEntry(for: testDate, entry: "Updated entry")
        
        // Then: Entry should be updated
        let entry = sut.getJournalEntry(for: testDate)
        XCTAssertEqual(entry, "Updated entry")
    }
    
    func testSetJournalEntry_EmptyString_StoresEmptyString() throws {
        // When: Setting empty journal entry
        sut.setJournalEntry(for: testDate, entry: "")
        
        // Then: Should store empty string
        let entry = sut.getJournalEntry(for: testDate)
        XCTAssertEqual(entry, "")
    }
    
    func testGetJournalEntry_NoEntry_ReturnsNil() throws {
        // When: Getting entry for date with no entry
        let entry = sut.getJournalEntry(for: testDate)
        
        // Then: Should be nil
        XCTAssertNil(entry)
    }
    
    func testJournalEntry_MultipleLines_PreservesFormatting() throws {
        // Given: Multi-line entry with special characters
        let multiLineEntry = """
        First line
        Second line with 🎉
        
        Third line after blank
        """
        
        // When: Setting and retrieving
        sut.setJournalEntry(for: testDate, entry: multiLineEntry)
        let retrieved = sut.getJournalEntry(for: testDate)
        
        // Then: Should preserve formatting
        XCTAssertEqual(retrieved, multiLineEntry)
    }
    
    // MARK: - Date Normalization Tests
    
    func testTodos_DifferentTimesOnSameDay_ShareTodoList() throws {
        // Given: Two different times on the same app day
        var morning = DateComponents()
        morning.year = 2025
        morning.month = 11
        morning.day = 8
        morning.hour = 6 // 6 AM
        let morningDate = calendar.date(from: morning)!
        
        var evening = DateComponents()
        evening.year = 2025
        evening.month = 11
        evening.day = 8
        evening.hour = 22 // 10 PM
        let eveningDate = calendar.date(from: evening)!
        
        // When: Adding todo to morning time
        sut.addTodo(for: morningDate, text: "Morning Todo")
        
        // Then: Should be visible in evening time (same app day)
        let eveningTodos = sut.getTodos(for: eveningDate)
        XCTAssertEqual(eveningTodos.count, 1)
        XCTAssertEqual(eveningTodos.first?.text, "Morning Todo")
    }
    
    func testTodos_AcrossMidnightSameAppDay_ShareTodoList() throws {
        // Given: 11 PM and 2 AM next day (same app day before 4am)
        var night = DateComponents()
        night.year = 2025
        night.month = 11
        night.day = 8
        night.hour = 23 // 11 PM
        let nightDate = calendar.date(from: night)!
        
        var earlyMorning = DateComponents()
        earlyMorning.year = 2025
        earlyMorning.month = 11
        earlyMorning.day = 9 // Next calendar day
        earlyMorning.hour = 2 // 2 AM
        let earlyMorningDate = calendar.date(from: earlyMorning)!
        
        // When: Adding todo at night
        sut.addTodo(for: nightDate, text: "Late Night Todo")
        
        // Then: Should be visible at 2 AM next day (same app day)
        let morningTodos = sut.getTodos(for: earlyMorningDate)
        XCTAssertEqual(morningTodos.count, 1)
        XCTAssertEqual(morningTodos.first?.text, "Late Night Todo")
    }
    
    // MARK: - Edge Cases
    
    func testTodos_VeryLongText_StoresCorrectly() throws {
        // Given: Very long todo text
        let longText = String(repeating: "A", count: 10000)
        
        // When: Adding todo with long text
        sut.addTodo(for: testDate, text: longText)
        
        // Then: Should store correctly
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.first?.text.count, 10000)
    }
    
    func testTodos_SpecialCharacters_StoresCorrectly() throws {
        // Given: Text with special characters
        let specialText = "Todo with émojis 🎉🎊 and spëcial çhars @#$%"
        
        // When: Adding todo
        sut.addTodo(for: testDate, text: specialText)
        
        // Then: Should store correctly
        let todos = sut.getTodos(for: testDate)
        XCTAssertEqual(todos.first?.text, specialText)
    }
    
    func testFocus_AllChoiceIds_WorkCorrectly() throws {
        // Given: All valid focus choice IDs (0-4)
        for choiceId in 0...4 {
            // When: Setting focus
            sut.setFocus(for: testDate, choiceId: choiceId)
            
            // Then: Should retrieve correctly
            let focus = sut.getFocus(for: testDate)
            XCTAssertEqual(focus?.choiceId, choiceId)
        }
    }
    
    func testMultipleOperations_MaintainConsistency() throws {
        // Given: Complex sequence of operations
        sut.setFocus(for: testDate, choiceId: 1)
        sut.addTodo(for: testDate, text: "First")
        sut.setJournalEntry(for: testDate, entry: "Journal entry")
        sut.addTodo(for: testDate, text: "Second")
        
        // When: Performing more operations
        let todoId = sut.getTodos(for: testDate).first!.id
        sut.toggleTodo(for: testDate, todoId: todoId)
        sut.setFocus(for: testDate, choiceId: 2)
        
        // Then: All data should be consistent
        XCTAssertEqual(sut.getFocus(for: testDate)?.choiceId, 2)
        XCTAssertEqual(sut.getTodos(for: testDate).count, 2)
        XCTAssertTrue(sut.getTodos(for: testDate).first?.isCompleted ?? false)
        XCTAssertEqual(sut.getJournalEntry(for: testDate), "Journal entry")
    }
}
