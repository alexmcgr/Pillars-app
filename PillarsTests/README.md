# Pillars App - Test Suite Documentation

## Overview
This test suite provides comprehensive coverage for the Pillars iOS application using XCTest, the native Xcode testing framework. The tests are designed to verify functionality, catch regressions, and ensure code quality during development.

## Test Files

### 1. DateUtilsTests.swift
**Purpose:** Tests the 4am app-day boundary logic that is core to the application's date handling.

**Coverage:**
- ✅ `appStartOfDay()` - Tests boundary conditions at 4am
- ✅ `appIsDateInToday()` - Validates today detection
- ✅ `appIsSameAppDay()` - Tests date comparison across midnight
- ✅ `appToday()`, `appYesterday()`, `appTomorrow()` - Date helper functions
- ✅ Edge cases: Month boundaries, year boundaries, leap years

**Key Test Scenarios:**
- Before 4am boundary (should count as previous day)
- At 4am boundary (should count as current day)
- After 4am boundary (should count as current day)
- Across midnight (11 PM to 2 AM same app day)
- Month/year boundaries
- Leap year handling

### 2. FocusStoreTests.swift
**Purpose:** Tests the core data store managing todos, focus selections, and journal entries.

**Coverage:**
- ✅ Todo CRUD operations (Create, Read, Update, Delete)
- ✅ Todo completion toggling
- ✅ Todo list management per date
- ✅ Focus selection management
- ✅ Journal entry management
- ✅ Date normalization for data isolation
- ✅ Edge cases: Empty inputs, long text, special characters

**Key Test Scenarios:**
- Adding/removing todos
- Toggling completion status
- Multiple todos maintaining order
- Separate todo lists for different dates
- Focus creation and updates
- Journal entry creation with multi-line text
- Date normalization (different times on same day share data)
- Across midnight same app-day behavior

### 3. TodoItemTests.swift
**Purpose:** Tests the TodoItem model and TodoRecurrence enum for data validation.

**Coverage:**
- ✅ TodoItem initialization (default and full)
- ✅ Unique ID generation
- ✅ Recurrence options (none, weekly, monthly)
- ✅ Reminder configuration
- ✅ Property mutations
- ✅ Combined features (recurring + reminder)
- ✅ TodoRecurrence enum validation
- ✅ Codable conformance

**Key Test Scenarios:**
- Default initialization with minimal parameters
- Full initialization with all properties
- Empty text handling
- Long text handling (5000+ characters)
- Special characters and emojis
- Unique ID verification
- All recurrence types
- Reminder with/without notification ID
- Mutable properties
- Recurring todo with reminder
- Codable encoding/decoding

### 4. NotificationManagerTests.swift
**Purpose:** Tests notification scheduling and time management functionality.

**Coverage:**
- ✅ Default notification times (journal, AM, PM)
- ✅ Time setting and persistence
- ✅ Todo reminder scheduling
- ✅ Notification ID generation
- ✅ Notification cancellation
- ✅ Edge cases: Empty titles, long titles, special characters
- ✅ Date/time combinations
- ✅ Past and future dates
- ✅ Time boundary tests (midnight, 23:59)

**Key Test Scenarios:**
- Default time initialization
- Setting custom notification times
- Scheduling todo reminders
- Notification ID format validation
- Multiple todo scheduling
- Empty and long title handling
- Special characters in titles
- Past/future date handling
- Time boundary edge cases
- Multiple operations

## Running the Tests

### Via Xcode
1. Open `Pillars.xcodeproj` in Xcode
2. Select the `PillarsTests` scheme
3. Press `Cmd+U` to run all tests
4. Or click the diamond next to any test method to run individually

### Via Command Line
```bash
cd /Users/alexmcgregor/Documents/Coding/Pillars-app
xcodebuild test -scheme Pillars -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running Specific Test Classes
```bash
# Run only DateUtils tests
xcodebuild test -scheme Pillars -only-testing:PillarsTests/DateUtilsTests

# Run only FocusStore tests
xcodebuild test -scheme Pillars -only-testing:PillarsTests/FocusStoreTests
```

## Test Coverage Summary

| Component | Test File | Test Count | Coverage |
|-----------|-----------|------------|----------|
| DateUtils | DateUtilsTests.swift | 18 tests | ✅ Comprehensive |
| FocusStore | FocusStoreTests.swift | 30+ tests | ✅ Comprehensive |
| TodoItem | TodoItemTests.swift | 25+ tests | ✅ Comprehensive |
| NotificationManager | NotificationManagerTests.swift | 30+ tests | ✅ Good |

**Total Test Count:** 100+ tests

## Testing Best Practices Applied

### 1. Arrange-Act-Assert (AAA) Pattern
All tests follow the AAA pattern for clarity:
```swift
func testExample() throws {
    // Given: Setup test data (Arrange)
    let input = "test"
    
    // When: Execute the operation (Act)
    let result = sut.process(input)
    
    // Then: Verify the outcome (Assert)
    XCTAssertEqual(result, "expected")
}
```

### 2. Clear Test Naming
Tests use descriptive names following the pattern:
`test[MethodName]_[Scenario]_[ExpectedBehavior]()`

Examples:
- `testAppStartOfDay_BeforeBoundary()`
- `testAddTodo_WithEmptyText_CreatesEmptyTodo()`
- `testToggleTodo_CompletesIncompleteTodo()`

### 3. Test Isolation
- Each test has its own setup and teardown
- No shared state between tests
- Tests can run in any order

### 4. Edge Case Coverage
Tests include boundary conditions:
- Empty inputs
- Maximum/minimum values
- Special characters
- Null/undefined values
- Date boundaries
- Time boundaries

### 5. Data Validation
Tests verify:
- Input validation
- Data type correctness
- Business rule enforcement
- State consistency

## Known Limitations

### NotificationManager Testing
- Tests verify API calls and data management
- Actual UNUserNotificationCenter behavior is not mocked
- Consider adding notification center mocking for true unit isolation

### Singleton Pattern
- NotificationManager and FocusStore use singleton pattern
- Tests may affect shared state
- Consider dependency injection for improved testability

### UI Testing
- Current suite focuses on business logic and data layers
- UI components (Views) are not unit tested
- Consider adding UI tests using XCUITest

## Future Test Additions

### Recommended Additional Tests
1. **StreakManager Tests** - If streak logic exists
2. **Recurring Todo Logic Tests** - More complex scenarios
3. **Integration Tests** - Test component interactions
4. **Performance Tests** - Measure critical operations
5. **UI Tests** - Verify user flows
6. **Notification Integration Tests** - With mocked notification center

### Mocking Opportunities
- **UNUserNotificationCenter** - Mock for notification tests
- **UserDefaults** - Mock for persistence tests
- **URLSession** - If weather API needs testing
- **Calendar** - For more deterministic date tests

## Continuous Integration

### GitHub Actions Example
```yaml
name: Run Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme Pillars \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -enableCodeCoverage YES
```

## Test Maintenance Guidelines

### When to Update Tests
1. **When adding new features** - Write tests first (TDD) or immediately after
2. **When fixing bugs** - Add regression tests
3. **When refactoring** - Ensure tests still pass
4. **When changing business logic** - Update relevant tests

### Test Hygiene
- Remove outdated tests
- Keep tests DRY (Don't Repeat Yourself)
- Use helper methods for common setup
- Document complex test scenarios
- Run full suite before committing

## Troubleshooting

### Common Issues

**Tests fail after date change:**
- Some tests use current date/time
- Run tests again to verify consistency

**Singleton state issues:**
- Tests may affect each other due to shared singletons
- Consider adding cleanup in tearDown methods

**Xcode test discovery:**
- Ensure test classes inherit from `XCTestCase`
- Test methods must start with `test`
- Import `@testable import Pillars`

## Contact & Support
For questions about the test suite, please consult the development team or review the inline test documentation.

---

**Last Updated:** November 8, 2025  
**Test Framework:** XCTest (Native iOS)  
**Minimum iOS Version:** iOS 14.0+
