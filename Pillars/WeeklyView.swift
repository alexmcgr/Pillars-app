//
//  WeeklyView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct WeeklyView: View {
    @ObservedObject var focusStore: FocusStore
    var selectedDate: Date = Date()
    @Environment(\.colorScheme) var colorScheme

    let weekDays = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            // Weekly calendar days
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    DayView(
                        day: day,
                        dayIndex: index,
                        focusStore: focusStore,
                        selectedDate: selectedDate
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(AppColors.tertiaryBackground(for: colorScheme))
    }
}

struct DayView: View {
    let day: String
    let dayIndex: Int
    @ObservedObject var focusStore: FocusStore
    var selectedDate: Date = Date()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // Get the color for this day's date
        let dayDate = getDayDate(for: dayIndex)
        let color = getColor(for: dayDate)
        let dayNumber = getDayNumber(for: dayIndex)

        VStack(spacing: 6) {
            Text(day)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text("\(dayNumber)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.primaryText(for: colorScheme))

            // Small color dot
            Circle()
                .fill(color ?? Color.clear)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 70)
        .background(AppColors.tertiaryBackground(for: colorScheme))
    }

    // Get the day number for a specific day index
    private func getDayNumber(for index: Int) -> Int {
        let calendar = Calendar.current
        let dayDate = getDayDate(for: index)
        return calendar.component(.day, from: dayDate)
    }

    // Get the date for a specific day index in the current week (starting Sunday)
    private func getDayDate(for index: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()

        // Find the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        // Calendar weekday: 1 = Sunday, 2 = Monday, etc.
        let daysFromSunday = weekday - 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) ?? today

        // Get the start of the day
        let startOfWeekDay = calendar.startOfDay(for: startOfWeek)

        return calendar.date(byAdding: .day, value: index, to: startOfWeekDay) ?? today
    }

    // Get the color for a specific date
    private func getColor(for date: Date) -> Color? {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }
}

#Preview {
    WeeklyView(focusStore: FocusStore())
}

