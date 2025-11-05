//
//  FullCalendarView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

// Helper struct for calendar cells
struct CalendarCell: Identifiable {
    let id = UUID()
    let day: Int?  // nil for empty cells
    let date: Date?
}

struct FullCalendarView: View {
    @ObservedObject var focusStore: FocusStore
    @State private var currentMonth: Date = Date()
    
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)
    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header with navigation
            monthHeader
            
            // Calendar grid (includes monthly summary now)
            calendarGrid
            
            Spacer()
        }
        .background(backgroundColor)
        .ignoresSafeArea()
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        // Swipe right - previous month
                        previousMonth()
                    } else if value.translation.width < -100 {
                        // Swipe left - next month
                        nextMonth()
                    }
                }
        )
    }
    
    private var monthHeader: some View {
        VStack(spacing: 0) {
            // Spacer to push content below Dynamic Island/status bar
            Rectangle()
                .fill(accentGray)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            // Month label with navigation arrows on same line
            HStack {
                Button(action: {
                    withAnimation {
                        previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthString)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        nextMonth()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70) // Padding to avoid Dynamic Island
            .padding(.bottom, 16)
        }
        .background(accentGray)
        .ignoresSafeArea(edges: .top)
    }
    
    private var calendarGrid: some View {
        let cells = generateCalendarCells()
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(accentGray)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(cells) { cell in
                    if let day = cell.day, let date = cell.date {
                        CalendarDayView(
                            day: day,
                            date: date,
                            focusStore: focusStore
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            
            // Monthly summary right under calendar
            monthlySummary
                .padding(.top, 12)
                .padding(.bottom, 12)
            
            Spacer()
        }
        .background(backgroundColor)
    }
    
    private func generateCalendarCells() -> [CalendarCell] {
        let calendar = Calendar.current
        var cells: [CalendarCell] = []
        
        // Get first day of the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return cells
        }
        
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Add empty cells for days before the first of the month
        // firstWeekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let emptyCellCount = firstWeekday - 1
        for _ in 0..<emptyCellCount {
            cells.append(CalendarCell(day: nil, date: nil))
        }
        
        // Add cells for each day of the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        for dayNumber in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: firstDayOfMonth) {
                cells.append(CalendarCell(day: dayNumber, date: calendar.startOfDay(for: date)))
            }
        }
        
        return cells
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private var monthlySummary: some View {
        let counts = getMonthlyCounts()
        
        return HStack(spacing: 16) {
            ForEach(FocusChoice.defaultChoices) { choice in
                HStack(spacing: 8) {
                    Circle()
                        .fill(choice.color.color)
                        .frame(width: 12, height: 12)
                    
                    Text("\(counts[choice.id] ?? 0)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
    
    private func getMonthlyCounts() -> [Int: Int] {
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        
        // Initialize all counts to 0
        for choice in FocusChoice.defaultChoices {
            counts[choice.id] = 0
        }
        
        // Get the month interval
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return counts
        }
        
        // Count focus selections for each day in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthInterval.start)?.count ?? 30
        for dayNumber in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthInterval.start),
               let focus = focusStore.getFocus(for: date) {
                counts[focus.choiceId, default: 0] += 1
            }
        }
        
        return counts
    }
}

struct CalendarDayView: View {
    let day: Int
    let date: Date
    @ObservedObject var focusStore: FocusStore
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(.white)
            
            // Color circle for focus
            if let color = getFocusColor() {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(isToday ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private func getFocusColor() -> Color? {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }
}

#Preview {
    FullCalendarView(focusStore: FocusStore())
}
