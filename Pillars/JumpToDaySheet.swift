//
//  JumpToDaySheet.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import SwiftUI

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
        let today = calendar.startOfDay(for: Date())

        for i in stride(from: -(dayRange - 1), through: 0, by: 1) {
            if let day = calendar.date(byAdding: .day, value: i, to: today) {
                days.append(day)
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
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Jump to a Day")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(AppColors.tertiaryBackground(for: colorScheme))

            // Recent days list
            ScrollView(.vertical, showsIndicators: true) {
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
                            HStack(spacing: 12) {
                                // Focus color dot
                                if let (color, _) = getFocusForDay(day) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                }

                                // Date and focus name
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateString(for: day))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                                    if let (_, label) = getFocusForDay(day) {
                                        Text(label)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("No focus set")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()

                                if isSelectedDate(day) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(for: colorScheme))
                        }
                    }
                }
            }

            Divider()

            // Show Calendar button
            Button(action: {
                showingFullCalendar = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Show Calendar")
                    Spacer()
                    Image(systemName: "chevron.up")
                        .rotationEffect(.degrees(showingFullCalendar ? 180 : 0))
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.primaryText(for: colorScheme))
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppColors.tertiaryBackground(for: colorScheme))
            }

            if showingFullCalendar {
                Divider()

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
                                isPresented = false
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .background(AppColors.background(for: colorScheme))
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    JumpToDaySheet(
        focusStore: FocusStore(),
        selectedDate: .constant(Date()),
        isPresented: .constant(true)
    )
}

