//
//  FocusMenuButton.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct FocusMenuButton: View {
    @ObservedObject var focusStore: FocusStore
    var selectedDate: Date
    @Binding var currentSelectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    @State private var showingJumpToDay = false

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    var body: some View {
        Menu {
            Section("Edit") {
                ForEach(FocusChoice.defaultChoices) { choice in
                    Button(
                        action: {
                            focusStore.setFocus(for: selectedDate, choiceId: choice.id)
                        },
                        label: {
                        HStack {
                            Circle()
                                .fill(choice.color.color)
                                .frame(width: 10, height: 10)
                            Text(choice.label)
                            if selectedFocusId == choice.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                        }
                    )
                }
            }

            Section("Navigate") {
                Button(
                    action: {
                        showingJumpToDay = true
                    },
                    label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Jump to Day")
                    }
                    }
                )
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)

                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
            }
        }
        .sheet(isPresented: $showingJumpToDay) {
            JumpToDaySheet(
                focusStore: focusStore,
                selectedDate: $currentSelectedDate,
                isPresented: $showingJumpToDay
            )
        }
    }
}

// MARK: - Jump to Day Sheet
struct JumpToDaySheet: View {
    @ObservedObject var focusStore: FocusStore
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showingFullCalendar = false

    private let dayRange = 14

    private var recentDays: [Date] {
        var days: [Date] = []
        let calendar = Calendar.current
        let appToday = DateUtils.appToday()

        for dayOffset in stride(from: -(dayRange - 1), through: 0, by: 1) {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: appToday) {
                days.append(DateUtils.appStartOfDay(for: day))
            }
        }
        return days.reversed()
    }

    private func getFocusForDay(_ day: Date) -> (color: Color, label: String)? {
        guard let focus = focusStore.getFocus(for: day),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return (choice.color.color, choice.label)
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func isSelectedDate(_ date: Date) -> Bool {
        DateUtils.appIsSameAppDay(date, selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            // Header
            HStack {
                Text("Jump to a Day")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Recent days list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(recentDays, id: \.self) { day in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = day
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 14) {
                                // Focus color dot
                                if let (color, _) = getFocusForDay(day) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 14, height: 14)
                                }

                                // Date and focus name
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateString(for: day))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                                    if let (_, label) = getFocusForDay(day) {
                                        Text(label)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("No focus set")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()

                                if isSelectedDate(day) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelectedDate(day) ? AppColors.tertiaryBackground(for: colorScheme).opacity(0.5) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 12)
            }

            // Show Calendar button
            Button(action: {
                showingFullCalendar = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                    Text("Show Calendar")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                .foregroundColor(AppColors.primaryText(for: colorScheme))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.tertiaryBackground(for: colorScheme).opacity(0.5))
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingFullCalendar) {
            NavigationView {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = newDate
                            }
                        }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingFullCalendar = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
