//
//  JournalView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct JournalView: View {
    @ObservedObject var focusStore: FocusStore
    @State private var selectedFilterCategoryId: Int?
    @State private var showingFilterSheet = false
    @Environment(\.colorScheme) var colorScheme

    // Get all journal entries grouped by month
    private var entriesByMonth: [(month: String, entries: [(date: Date, entry: String, focus: DailyFocus)])] {
        let allEntries = focusStore.getAllJournalEntries()
        
        // Filter by category if selected
        let filteredEntries: [(date: Date, entry: String, focus: DailyFocus)]
        if let categoryId = selectedFilterCategoryId {
            filteredEntries = allEntries.filter { $0.focus.choiceId == categoryId }
        } else {
            filteredEntries = allEntries
        }
        
        // Group by month
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            let components = calendar.dateComponents([.year, .month], from: entry.date)
            return calendar.date(from: components) ?? entry.date
        }
        
        // Sort months descending (newest first)
        let sortedMonths = grouped.keys.sorted(by: >)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        return sortedMonths.compactMap { monthDate in
            guard let entries = grouped[monthDate] else { return nil }
            // Sort entries within month (newest first)
            let sortedEntries = entries.sorted { $0.date > $1.date }
            return (formatter.string(from: monthDate), sortedEntries)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                FocusGradientBackground(
                    focusColor: focusStore.getTodayColor(),
                    colorScheme: colorScheme
                )

                Group {
                    if entriesByMonth.isEmpty {
                        VStack(spacing: 16) {
                            Text("No journal entries")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Start writing to see your entries here")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        List {
                            ForEach(entriesByMonth, id: \.month) { monthData in
                                // Month header as a list row
                                HStack {
                                    Text(monthData.month)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                
                                // Journal entries for this month
                                ForEach(monthData.entries, id: \.date) { entry in
                                    JournalEntryRow(
                                        date: entry.date,
                                        entry: entry.entry,
                                        focus: entry.focus,
                                        focusStore: focusStore
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Journal")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            FocusMenuButton(
                                focusStore: focusStore,
                                selectedDate: Date(),
                                currentSelectedDate: .constant(Date())
                            )
                        }
                    }
                }

                // Floating filter button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)

                                if selectedFilterCategoryId != nil {
                                    Circle()
                                        .fill(getFilterCategoryColor().opacity(0.3))
                                }

                                Group {
                                    if selectedFilterCategoryId != nil {
                                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(getFilterCategoryColor())
                                    } else {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppColors.primaryText(for: colorScheme))
                                    }
                                }
                            }
                            .frame(width: 56, height: 56)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                selectedCategoryId: $selectedFilterCategoryId,
                focusStore: focusStore
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.automatic)
        }
    }

    private func getFilterCategoryColor() -> Color {
        guard let categoryId = selectedFilterCategoryId,
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == categoryId }) else {
            return Color(red: 0/255, green: 122/255, blue: 255/255) // Default blue
        }
        return choice.color.color
    }

}

struct JournalEntryRow: View {
    let date: Date
    let entry: String
    let focus: DailyFocus
    @ObservedObject var focusStore: FocusStore
    @Environment(\.colorScheme) var colorScheme

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var focusName: String? {
        guard let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.label
    }

    private var focusColor: Color? {
        guard let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return nil
        }
        return choice.color.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and focus header
            HStack(spacing: 8) {
                Text(dateString)
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
            Text(entry)
                .font(.system(size: 15))
                .foregroundColor(AppColors.primaryText(for: colorScheme))
                .lineLimit(nil)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
    }
}

struct FilterSheet: View {
    @Binding var selectedCategoryId: Int?
    @ObservedObject var focusStore: FocusStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var accentColor: Color {
        focusStore.getTodayColor() ?? Color.blue
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    List {
                        // All categories option
                        Button(action: {
                            selectedCategoryId = nil
                            dismiss()
                        }) {
                            HStack {
                                Text("All Categories")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                                Spacer()
                                if selectedCategoryId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                        .listRowBackground(AppColors.tertiaryBackground(for: colorScheme))

                        // Individual category options
                        ForEach(FocusChoice.defaultChoices) { choice in
                            Button(action: {
                                selectedCategoryId = choice.id
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(choice.color.color)
                                        .frame(width: 24, height: 24)

                                    Text(choice.label)
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                                    Spacer()

                                    if selectedCategoryId == choice.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(accentColor)
                                    }
                                }
                            }
                            .listRowBackground(AppColors.tertiaryBackground(for: colorScheme))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background(for: colorScheme))
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
    }
}

#Preview {
    JournalView(focusStore: FocusStore())
}
