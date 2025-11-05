//
//  WeeklyView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct WeeklyView: View {
    @ObservedObject var focusStore: FocusStore
    
    let weekDays = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Light gray background extending over status bar area
            accentGray
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            // Weekly calendar days - colors start below status bar
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    DayView(
                        day: day,
                        dayIndex: index,
                        focusStore: focusStore
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 60) // Add padding to push content below status bar/Dynamic Island
            .padding(.bottom, 12)
        }
        .background(accentGray)
        .ignoresSafeArea(edges: .top)
    }
}

struct DayView: View {
    let day: String
    let dayIndex: Int
    @ObservedObject var focusStore: FocusStore
    
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)
    
    var body: some View {
        // Get the color for this day's date
        let dayDate = getDayDate(for: dayIndex)
        let color = getColor(for: dayDate)
        let dayNumber = getDayNumber(for: dayIndex)
        
        VStack(spacing: 6) {
            Text(day)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(dayNumber)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Small color dot
            Circle()
                .fill(color ?? Color.clear)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 70)
        .background(accentGray)
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

