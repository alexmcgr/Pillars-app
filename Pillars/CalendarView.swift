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
    @State private var currentMonth: Date = Date()
    
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)
    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month header with navigation
                monthHeader
                
                // Calendar grid
                calendarGrid
            }
            .background(backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: {
                previousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                nextMonth()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(accentGray)
    }
    
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
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(accentGray)
            
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
                        focusStore: focusStore
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(backgroundColor)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// CalendarDayView is now defined in FullCalendarView.swift
// This file is kept for backward compatibility but CalendarDayView is shared

#Preview {
    CalendarView(focusStore: FocusStore())
}

