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
    @State private var menuSelectedDate: Date = Date()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                FocusGradientBackground(
                    focusColor: focusStore.getTodayColor(),
                    colorScheme: colorScheme
                )

                ScrollView {
                    VStack(spacing: 0) {
                        // Calendar grid
                        calendarGrid
                            .padding(.horizontal, 8)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        // Journal entry section
                        if let selectedDate = selectedDate {
                            VStack(spacing: 0) {
                                // Section header
                                HStack {
                                    Text("Journal Entry")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                                // Journal entry card
                                journalEntryCard(for: selectedDate)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 24)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(monthNameOnly)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FocusMenuButton(
                        focusStore: focusStore,
                        selectedDate: selectedDate ?? Date(),
                        currentSelectedDate: $menuSelectedDate
                    )
                }
            }
        }
        .onAppear {
            // Default to today if no date selected
            if selectedDate == nil {
                selectedDate = Date()
            }
        }
    }

    private var calendarGrid: some View {
        let cells = generateCalendarCells()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
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
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var monthNameOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }

    private func journalEntryCard(for date: Date) -> some View {
        let entry = focusStore.getJournalEntry(for: date)
        let focusName = getFocusName(for: date)
        let focusColor = getFocusColor(for: date)

        return VStack(alignment: .leading, spacing: 12) {
            // Date and focus header
            HStack(spacing: 8) {
                Text(dateString(for: date))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                if let focusName = focusName, let focusColor = focusColor {
                    Circle()
                        .fill(focusColor)
                        .frame(width: 6, height: 6)

                    Text(focusName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Journal entry text
            if let entry = entry, !entry.isEmpty {
                Text(entry)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                    .lineLimit(nil)
            } else {
                Text("No journal entry for this day")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private func getFocusName(for date: Date) -> String? {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.label
    }

    private func getFocusColor(for date: Date) -> Color? {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }
}

struct CalendarDayView: View {
    let day: Int
    let date: Date
    let isSelected: Bool
    @ObservedObject var focusStore: FocusStore
    var onTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme

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
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.system(size: 16, weight: isToday ? .semibold : .regular))
                    .foregroundColor(
                        isSelected ? AppColors.primaryText(for: colorScheme) :
                        isToday ? Color.blue :
                        AppColors.primaryText(for: colorScheme)
                    )

                // Color indicators
                ZStack {
                    // Ring if there's a journal entry
                    if hasJournalEntry {
                        Circle()
                            .stroke(AppColors.primaryText(for: colorScheme), lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                    }
                    // Colored dot for focus
                    if let color = getFocusColor() {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColors.tertiaryBackground(for: colorScheme) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppColors.primaryText(for: colorScheme).opacity(0.3) :
                        isToday ? Color.blue.opacity(0.5) :
                        Color.clear,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
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
