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
    @State private var selectedDate: Date? = Date()
    @State private var slideDirection: SlideDirection = .none
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)
    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    
    enum SlideDirection {
        case left, right, none
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // Month header with navigation
                    monthHeader
                    
                    Spacer()
                }
                
                // Calendar grids layer - all aligned to top
                VStack(spacing: 0) {
                    // Spacer to position below header
                    monthHeader
                        .opacity(0) // Invisible spacer the same size as header
                    
                    // Calendar grid with drag gesture
                    ZStack(alignment: .top) {
                        calendarGrid
                            .offset(x: dragOffset)
                        
                        // Preview of previous/next month
                        if abs(dragOffset) > 50 {
                            if dragOffset > 0 {
                                // Previous month preview
                                previousMonthPreview
                                    .offset(x: dragOffset - geometry.size.width)
                            } else {
                                // Next month preview
                                nextMonthPreview
                                    .offset(x: dragOffset + geometry.size.width)
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold: CGFloat = 100
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            
                            if value.translation.width > threshold || velocity > 500 {
                                // Swipe right - previous month
                                slideDirection = .right
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = geometry.size.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    previousMonth()
                                    dragOffset = 0
                                }
                            } else if value.translation.width < -threshold || velocity < -500 {
                                // Swipe left - next month
                                slideDirection = .left
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = -geometry.size.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    nextMonth()
                                    dragOffset = 0
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .background(backgroundColor)
        .ignoresSafeArea()
        .onAppear {
            // Default to today if no date selected
            if selectedDate == nil {
                selectedDate = Date()
            }
        }
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
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date()),
                            focusStore: focusStore,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .id(monthString)
            .transition(.asymmetric(
                insertion: .move(edge: slideDirection == .left ? .trailing : .leading),
                removal: .move(edge: slideDirection == .left ? .leading : .trailing)
            ))
            
            // Journal entry display
            if let selectedDate = selectedDate {
                journalEntryDisplay(for: selectedDate, entry: focusStore.getJournalEntry(for: selectedDate))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
            }
            
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
    
    private var previousMonthPreview: some View {
        let calendar = Calendar.current
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        return calendarGridFor(month: prevMonth)
    }
    
    private var nextMonthPreview: some View {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return calendarGridFor(month: nextMonth)
    }
    
    private func calendarGridFor(month: Date) -> some View {
        let cells = generateCalendarCellsFor(month: month)
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
                            isSelected: false,
                            focusStore: focusStore,
                            onTap: nil
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
        }
        .background(backgroundColor)
    }
    
    private func generateCalendarCellsFor(month: Date) -> [CalendarCell] {
        let calendar = Calendar.current
        var cells: [CalendarCell] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return cells
        }
        
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyCellCount = firstWeekday - 1
        
        for _ in 0..<emptyCellCount {
            cells.append(CalendarCell(day: nil, date: nil))
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        for dayNumber in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: firstDayOfMonth) {
                cells.append(CalendarCell(day: dayNumber, date: calendar.startOfDay(for: date)))
            }
        }
        
        return cells
    }
    
    private func journalEntryDisplay(for date: Date, entry: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(dateString(for: date))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let focusName = getFocusName(for: date) {
                        Text(" • ")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(focusName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            if let entry = entry, !entry.isEmpty {
                Text(entry)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentGray)
                    .cornerRadius(8)
            } else {
                Text("No journal entry for this day")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentGray)
                    .cornerRadius(8)
            }
        }
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getFocusName(for date: Date) -> String? {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.label
    }
}

struct CalendarDayView: View {
    let day: Int
    let date: Date
    let isSelected: Bool
    @ObservedObject var focusStore: FocusStore
    var onTap: (() -> Void)?
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var hasJournalEntry: Bool {
        focusStore.getJournalEntry(for: date) != nil
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(.white)
                
                // Today indicator - small underline
                if isToday {
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 20, height: 1)
                        .offset(y: -2)
                }
                
                // Color circle for focus with optional white ring for journal
                if let color = getFocusColor() {
                    ZStack {
                        // White ring if there's a journal entry
                        if hasJournalEntry {
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                        }
                        // Colored dot
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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
