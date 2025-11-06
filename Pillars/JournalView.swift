//
//  JournalView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct JournalView: View {
    @ObservedObject var focusStore: FocusStore
    @State private var currentMonth: Date = Date()
    @State private var selectedFilterCategoryId: Int?
    @State private var showingFilterSheet = false
    @Environment(\.colorScheme) var colorScheme

    private var journalEntries: [(date: Date, entry: String, focus: DailyFocus)] {
        let entries = focusStore.getJournalEntries(for: currentMonth)
        if let categoryId = selectedFilterCategoryId {
            return entries.filter { $0.focus.choiceId == categoryId }
        }
        return entries
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentMonth)
    }

    var body: some View {
        NavigationView {
            ZStack {
                FocusGradientBackground(
                    focusColor: focusStore.getTodayColor(),
                    colorScheme: colorScheme
                )

                List {
                    Section {
                        if journalEntries.isEmpty {
                            VStack(spacing: 16) {
                                Text("No journal entries")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("for \(monthString)")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        } else {
                            ForEach(journalEntries, id: \.date) { entry in
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
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .navigationTitle("Journal")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        FocusMenuButton(focusStore: focusStore, selectedDate: Date())
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 16) {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                            }
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                            }
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

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = newMonth
            }
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
        formatter.dateFormat = "EEEE, MMMM d"
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

