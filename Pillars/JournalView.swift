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
    @State private var selectedFilterCategoryId: Int? = nil
    @State private var showingFilterSheet = false

    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)

    private var journalEntries: [(date: Date, entry: String, focus: DailyFocus)] {
        let entries = focusStore.getJournalEntries(for: currentMonth)
        if let categoryId = selectedFilterCategoryId {
            return entries.filter { $0.focus.choiceId == categoryId }
        }
        return entries
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Month header with navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(monthString)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Journal entries list
                if journalEntries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("No journal entries")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("for \(monthString)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(journalEntries, id: \.date) { entry in
                                JournalEntryRow(
                                    date: entry.date,
                                    entry: entry.entry,
                                    focus: entry.focus,
                                    focusStore: focusStore
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Extra padding for filter button
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
                        Image(systemName: selectedFilterCategoryId != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(selectedFilterCategoryId != nil ? getFilterCategoryColor() : Color(red: 48/255, green: 48/255, blue: 48/255))
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                selectedCategoryId: $selectedFilterCategoryId,
                focusStore: focusStore
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
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

    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(dateString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if let focusName = focusName, let focusColor = focusColor {
                        Text(" • ")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(focusColor)

                        Text(focusName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()
            }

            Text(entry)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentGray)
                .cornerRadius(8)
        }
    }
}

struct FilterSheet: View {
    @Binding var selectedCategoryId: Int?
    @ObservedObject var focusStore: FocusStore
    @Environment(\.dismiss) var dismiss

    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    private let accentGray = Color(red: 48/255, green: 48/255, blue: 48/255)

    private var accentColor: Color {
        focusStore.getTodayColor() ?? Color.blue
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
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
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedCategoryId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                        .listRowBackground(accentGray)

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
                                        .foregroundColor(.white)

                                    Spacer()

                                    if selectedCategoryId == choice.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(accentColor)
                                    }
                                }
                            }
                            .listRowBackground(accentGray)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
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

