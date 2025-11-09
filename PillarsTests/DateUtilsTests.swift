//
//  DateUtilsTests.swift
//  PillarsTests
//
//  Created by Cascade on 11/8/25.
//

import XCTest
@testable import Pillars

final class DateUtilsTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar.current
        calendar.timeZone = TimeZone.current
    }
    
    override func tearDownWithError() throws {
        calendar = nil
        try super.tearDownWithError()
    }
    
    // MARK: - appStartOfDay Tests
    
    func testAppStartOfDay_BeforeBoundary() throws {
        // Given: 3:00 AM on Nov 8, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 3
        components.minute = 0
        components.second = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Nov 7, 2025 (previous day)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 11)
        XCTAssertEqual(resultComponents.day, 7, "Before 4am should count as previous day")
    }
    
    func testAppStartOfDay_AtBoundary() throws {
        // Given: 4:00 AM on Nov 8, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Nov 8, 2025 (same day)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 11)
        XCTAssertEqual(resultComponents.day, 8, "At 4am should count as current day")
    }
    
    func testAppStartOfDay_AfterBoundary() throws {
        // Given: 5:00 PM on Nov 8, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 17
        components.minute = 30
        components.second = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Nov 8, 2025 (same day)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 11)
        XCTAssertEqual(resultComponents.day, 8, "After 4am should count as current day")
    }
    
    func testAppStartOfDay_Midnight() throws {
        // Given: Midnight (00:00) on Nov 8, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Nov 7, 2025 (previous day, before 4am boundary)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 11)
        XCTAssertEqual(resultComponents.day, 7, "Midnight should count as previous day")
    }
    
    func testAppStartOfDay_AlmostBoundary() throws {
        // Given: 3:59 AM on Nov 8, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 3
        components.minute = 59
        components.second = 59
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Nov 7, 2025
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.day, 7, "One second before 4am should count as previous day")
    }
    
    // MARK: - appIsDateInToday Tests
    
    func testAppIsDateInToday_CurrentTime() throws {
        // Given: Current date/time
        let now = Date()
        
        // When: Checking if it's today
        let result = DateUtils.appIsDateInToday(now, calendar: calendar)
        
        // Then: Should be true
        XCTAssertTrue(result, "Current time should be in today")
    }
    
    func testAppIsDateInToday_Yesterday() throws {
        // Given: Yesterday at noon
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        var components = calendar.dateComponents([.year, .month, .day], from: yesterday)
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!
        
        // When: Checking if it's today
        let result = DateUtils.appIsDateInToday(date, calendar: calendar)
        
        // Then: Should be false
        XCTAssertFalse(result, "Yesterday should not be today")
    }
    
    func testAppIsDateInToday_Tomorrow() throws {
        // Given: Tomorrow at noon
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!
        
        // When: Checking if it's today
        let result = DateUtils.appIsDateInToday(date, calendar: calendar)
        
        // Then: Should be false
        XCTAssertFalse(result, "Tomorrow should not be today")
    }
    
    // MARK: - appIsSameAppDay Tests
    
    func testAppIsSameAppDay_SameDay_DifferentTimes() throws {
        // Given: Two times on the same app day
        var components1 = DateComponents()
        components1.year = 2025
        components1.month = 11
        components1.day = 8
        components1.hour = 10
        components1.minute = 0
        
        var components2 = DateComponents()
        components2.year = 2025
        components2.month = 11
        components2.day = 8
        components2.hour = 22
        components2.minute = 0
        
        let date1 = calendar.date(from: components1)!
        let date2 = calendar.date(from: components2)!
        
        // When: Comparing app days
        let result = DateUtils.appIsSameAppDay(date1, date2, calendar: calendar)
        
        // Then: Should be true
        XCTAssertTrue(result, "Same calendar day after 4am should be same app day")
    }
    
    func testAppIsSameAppDay_AcrossMidnight_SameAppDay() throws {
        // Given: 11 PM and 2 AM (next calendar day, but same app day)
        var components1 = DateComponents()
        components1.year = 2025
        components1.month = 11
        components1.day = 8
        components1.hour = 23
        components1.minute = 0
        
        var components2 = DateComponents()
        components2.year = 2025
        components2.month = 11
        components2.day = 9
        components2.hour = 2
        components2.minute = 0
        
        let date1 = calendar.date(from: components1)!
        let date2 = calendar.date(from: components2)!
        
        // When: Comparing app days
        let result = DateUtils.appIsSameAppDay(date1, date2, calendar: calendar)
        
        // Then: Should be true (both belong to Nov 8 app day)
        XCTAssertTrue(result, "11 PM and 2 AM next day should be same app day")
    }
    
    func testAppIsSameAppDay_DifferentDays() throws {
        // Given: 5 PM on Nov 8 and 5 PM on Nov 9
        var components1 = DateComponents()
        components1.year = 2025
        components1.month = 11
        components1.day = 8
        components1.hour = 17
        components1.minute = 0
        
        var components2 = DateComponents()
        components2.year = 2025
        components2.month = 11
        components2.day = 9
        components2.hour = 17
        components2.minute = 0
        
        let date1 = calendar.date(from: components1)!
        let date2 = calendar.date(from: components2)!
        
        // When: Comparing app days
        let result = DateUtils.appIsSameAppDay(date1, date2, calendar: calendar)
        
        // Then: Should be false
        XCTAssertFalse(result, "Different calendar days after 4am should be different app days")
    }
    
    // MARK: - appToday Tests
    
    func testAppToday_ReturnsNormalizedDate() throws {
        // When: Getting app today
        let result = DateUtils.appToday(calendar: calendar)
        
        // Then: Should be normalized to start of day
        let components = calendar.dateComponents([.hour, .minute, .second], from: result)
        XCTAssertEqual(components.hour, 0, "Should be midnight")
        XCTAssertEqual(components.minute, 0, "Should have no minutes")
        XCTAssertEqual(components.second, 0, "Should have no seconds")
    }
    
    func testAppToday_ConsistentWithinAppDay() throws {
        // Given: Getting app today multiple times
        let today1 = DateUtils.appToday(calendar: calendar)
        let today2 = DateUtils.appToday(calendar: calendar)
        
        // Then: Should be equal
        XCTAssertEqual(today1, today2, "Multiple calls to appToday should return same date")
    }
    
    // MARK: - appYesterday Tests
    
    func testAppYesterday_ReturnsOneDayBefore() throws {
        // Given: App today
        let today = DateUtils.appToday(calendar: calendar)
        
        // When: Getting app yesterday
        let yesterday = DateUtils.appYesterday(calendar: calendar)
        
        // Then: Should be exactly one day before
        let daysDifference = calendar.dateComponents([.day], from: yesterday, to: today).day
        XCTAssertEqual(daysDifference, 1, "Yesterday should be one day before today")
    }
    
    // MARK: - appTomorrow Tests
    
    func testAppTomorrow_ReturnsOneDayAfter() throws {
        // Given: App today
        let today = DateUtils.appToday(calendar: calendar)
        
        // When: Getting app tomorrow
        let tomorrow = DateUtils.appTomorrow(calendar: calendar)
        
        // Then: Should be exactly one day after
        let daysDifference = calendar.dateComponents([.day], from: today, to: tomorrow).day
        XCTAssertEqual(daysDifference, 1, "Tomorrow should be one day after today")
    }
    
    // MARK: - Edge Cases
    
    func testAppStartOfDay_MonthBoundary() throws {
        // Given: 2 AM on Nov 1, 2025 (should belong to Oct 31)
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 1
        components.hour = 2
        components.minute = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Oct 31
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 10)
        XCTAssertEqual(resultComponents.day, 31, "Should handle month boundary correctly")
    }
    
    func testAppStartOfDay_YearBoundary() throws {
        // Given: 2 AM on Jan 1, 2026 (should belong to Dec 31, 2025)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 2
        components.minute = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Dec 31, 2025
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2025)
        XCTAssertEqual(resultComponents.month, 12)
        XCTAssertEqual(resultComponents.day, 31, "Should handle year boundary correctly")
    }
    
    func testAppStartOfDay_LeapYearFebruary() throws {
        // Given: 2 AM on Mar 1, 2024 (leap year, should belong to Feb 29)
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 1
        components.hour = 2
        components.minute = 0
        
        let date = calendar.date(from: components)!
        
        // When: Getting app start of day
        let result = DateUtils.appStartOfDay(for: date, calendar: calendar)
        
        // Then: Should be Feb 29, 2024
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(resultComponents.year, 2024)
        XCTAssertEqual(resultComponents.month, 2)
        XCTAssertEqual(resultComponents.day, 29, "Should handle leap year correctly")
    }
}
