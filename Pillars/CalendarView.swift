//
//  CalendarView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var focusStore: FocusStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMonth: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar grid
                calendarGrid
            }
            .background(AppColors.background(for: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.primaryText(for: colorScheme))
                    }
                }
            }
        }
    }

    // Month header with navigation removed per design

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        let daysFromPreviousMonth = (firstWeekday - 1) % 7 // Adjust for Sunday start

        // Weekday headers
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.tertiaryBackground(for: colorScheme))

            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                // Days from previous month (empty)
                ForEach(0..<daysFromPreviousMonth, id: \.self) { _ in
                    Color.clear
                        .frame(height: 50)
                }

                // Days in current month
                ForEach(1...daysInMonth, id: \.self) { day in
                    // Using CalendarDayView from FullCalendarView.swift
                    CalendarDayView(
                        day: day,
                        date: calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!,
                        isSelected: false,
                        focusStore: focusStore,
                        onTap: nil
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(AppColors.background(for: colorScheme))
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // Month navigation removed per design
}

// CalendarDayView is now defined in FullCalendarView.swift
// This file is kept for backward compatibility but CalendarDayView is shared

#Preview {
    CalendarView(focusStore: FocusStore())
}

