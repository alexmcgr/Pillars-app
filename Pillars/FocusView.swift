//
//  FocusView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct FocusView: View {
    @ObservedObject var focusStore: FocusStore
    @ObservedObject var streakManager: StreakManager
    @StateObject private var cardOrderManager = CardOrderManager.shared
    @State private var selectedDate: Date = Date()
    @State private var showingJournalSheet = false
    @State private var journalText: String = ""
    @State private var showTestSplash = false
    @State private var weatherData: WeatherData?
    @State private var isLoadingWeather = false
    @Environment(\.colorScheme) var colorScheme

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    private var selectedFocusChoice: FocusChoice? {
        guard let id = selectedFocusId else { return nil }
        return FocusChoice.defaultChoices.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationView {
            ZStack {
                FocusGradientBackground(
                    focusColor: selectedFocusChoice?.color.color,
                    colorScheme: colorScheme
                )

                ScrollView {
                    VStack(spacing: 16) {
                        // Header section with focus info
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Dynamic card ordering
                        ForEach(cardOrderManager.cardOrder) { card in
                            cardView(for: card)
                                .padding(.horizontal, 16)
                        }

                        // Spacer for future features
                        Spacer(minLength: 200)
                    }
                }
                .scrollContentBackground(.hidden)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            // Only navigate if swipe is more horizontal than vertical
                            if abs(horizontalAmount) > abs(verticalAmount) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if horizontalAmount < 0 {
                                        // Swipe left - next day
                                        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                            selectedDate = nextDay
                                        }
                                    } else {
                                        // Swipe right - previous day
                                        if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                            selectedDate = prevDay
                                        }
                                    }
                                }
                            }
                        }
                )

                // Test splash screen overlay
                if showTestSplash {
                    DailyFocusSplash(focusStore: focusStore, isPresented: $showTestSplash)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .navigationTitle(actualDateString)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FocusMenuButton(focusStore: focusStore, selectedDate: selectedDate, currentSelectedDate: $selectedDate)
                }
            }
        }
        .sheet(isPresented: $showingJournalSheet) {
            JournalEntrySheet(
                text: $journalText,
                accentColor: getJournalEntryColor(for: selectedDate),
                onSave: {
                    focusStore.setJournalEntry(for: selectedDate, entry: journalText)
                    showingJournalSheet = false
                },
                onCancel: {
                    journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
                    showingJournalSheet = false
                }
            )
        }
        .onAppear {
            // Load existing journal entry if there is one
            journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
            // Load weather if it's today
            if isToday {
                loadWeather()
            }
        }
        .onChange(of: selectedDate) { _ in
            // Update journal text when date changes
            journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
            // Load weather if it's today, clear if not
            if isToday {
                loadWeather()
            } else {
                weatherData = nil
            }
        }
    }
    
    private func loadWeather() {
        guard isToday else { return }
        Task {
            isLoadingWeather = true
            do {
                let weather = try await WeatherService.shared.fetchWeather()
                await MainActor.run {
                    weatherData = weather
                    isLoadingWeather = false
                }
            } catch {
                print("Weather error: \(error)")
                await MainActor.run {
                    isLoadingWeather = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func cardView(for card: HomeScreenCard) -> some View {
        switch card {
        case .todo:
            TodoListCard(focusStore: focusStore, selectedDate: selectedDate)
        case .journal:
            JournalEntryCard(
                selectedDate: selectedDate,
                focusStore: focusStore,
                onTap: {
                    journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
                    showingJournalSheet = true
                }
            )
        case .streaks:
            StreaksCard(
                streakManager: streakManager,
                focusStore: focusStore,
                selectedDate: selectedDate
            )
        case .dateNavigation:
            DateNavigationCard(selectedDate: $selectedDate, focusStore: focusStore)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let choice = selectedFocusChoice {
                    // Color dot next to focus name
                    Circle()
                        .fill(choice.color.color)
                        .frame(width: 8, height: 8)

                    Text(choice.label)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)

                    if let relativeDayText = relativeDayText {
                        Text("•")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.tertiary)
                        Text(relativeDayText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("No focus set")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)

                    if let relativeDayText = relativeDayText {
                        Text("•")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.tertiary)
                        Text(relativeDayText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // Weather info (only show when it's today)
            if isToday, let weather = weatherData {
                CompactWeatherView(weather: weather)
            } else if isToday, isLoadingWeather {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Loading weather...")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func getJournalEntryColor(for date: Date) -> Color {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return Color.blue
        }
        return choice.color.color
    }

    private var actualDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: selectedDate)

        let day = Calendar.current.component(.day, from: selectedDate)
        let suffix = ordinalSuffix(for: day)

        return "\(monthName) \(day)\(suffix)"
    }

    private func ordinalSuffix(for day: Int) -> String {
        let lastDigit = day % 10
        let lastTwoDigits = day % 100

        // Special cases for 11th, 12th, 13th
        if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
            return "th"
        }

        // Otherwise, use the last digit
        switch lastDigit {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    private var relativeDayText: String? {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        return nil
    }
}

// MARK: - Todo List Card
struct TodoListCard: View {
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddTodo = false
    @State private var newTodoText = ""

    private var todos: [TodoItem] {
        focusStore.getTodos(for: selectedDate)
    }

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue
        }
        return choice.color.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 24))
                    .foregroundColor(focusColor)

                Text("To-Do")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()

                Button(action: {
                    showingAddTodo = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                }
            }

            if todos.isEmpty {
                Text("No tasks for today")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(todos) { todo in
                        TodoRow(
                            todo: todo,
                            focusStore: focusStore,
                            selectedDate: selectedDate
                        ) {
                            focusStore.toggleTodo(for: selectedDate, todoId: todo.id)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
        .sheet(isPresented: $showingAddTodo) {
            AddTodoSheet(newTodoText: $newTodoText) {
                if !newTodoText.isEmpty {
                    focusStore.addTodo(for: selectedDate, text: newTodoText)
                    newTodoText = ""
                    showingAddTodo = false
                }
            }
            .presentationDetents([.height(200)])
        }
    }
}

struct TodoRow: View {
    let todo: TodoItem
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    let onToggle: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue // Default to blue if no focus set
        }
        return choice.color.color
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(todo.isCompleted ? focusColor : .secondary)

                Text(todo.text)
                    .font(.system(size: 15))
                    .foregroundColor(todo.isCompleted ? .secondary : AppColors.primaryText(for: colorScheme))
                    .strikethrough(todo.isCompleted)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddTodoSheet: View {
    @Binding var newTodoText: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("New task", text: $newTodoText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Spacer()
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(newTodoText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let selectedDate: Date
    @ObservedObject var focusStore: FocusStore
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var hasEntry: Bool {
        focusStore.getJournalEntry(for: selectedDate) != nil
    }

    private var entryPreview: String? {
        if let entry = focusStore.getJournalEntry(for: selectedDate), !entry.isEmpty {
            return String(entry.prefix(100))
        }
        return nil
    }

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue
        }
        return choice.color.color
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: hasEntry ? "note.text" : "square.and.pencil")
                        .font(.system(size: 24))
                        .foregroundColor(focusColor)

                    Text("Journal Entry")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                if let preview = entryPreview {
                    Text(preview)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Add a journal entry for today")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.tertiaryBackground(for: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Journal Entry Sheet
struct JournalEntrySheet: View {
    @Binding var text: String
    let accentColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .font(.system(size: 17))
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focused($isTextFieldFocused)
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Date Navigation Card
struct DateNavigationCard: View {
    @Binding var selectedDate: Date
    @ObservedObject var focusStore: FocusStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDatePicker = false

    private var focusColor: Color {
        guard let focus = focusStore.getFocus(for: selectedDate),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return .blue
        }
        return choice.color.color
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: selectedDate)
        let day = Calendar.current.component(.day, from: selectedDate)
        let suffix = ordinalSuffix(for: day)
        return "\(monthName) \(day)\(suffix)"
    }

    private var relativeDayText: String? {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        return nil
    }

    private func ordinalSuffix(for day: Int) -> String {
        let lastDigit = day % 10
        let lastTwoDigits = day % 100
        if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
            return "th"
        }
        switch lastDigit {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(focusColor)

                Text("Date")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()
            }

            HStack(spacing: 16) {
                // Previous day button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                            selectedDate = prevDay
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(focusColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppColors.tertiaryBackground(for: colorScheme))
                        )
                }
                .buttonStyle(PlainButtonStyle())

                // Date display (tappable to open date picker)
                Button(action: {
                    showingDatePicker = true
                }) {
                    VStack(spacing: 4) {
                        Text(dateString)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primaryText(for: colorScheme))

                        if let relativeText = relativeDayText {
                            Text(relativeText)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())

                // Next day button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                            selectedDate = nextDay
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(focusColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppColors.tertiaryBackground(for: colorScheme))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                        .foregroundColor(focusColor)
                    }
                }
            }
        }
    }
}

// MARK: - Compact Weather View
struct CompactWeatherView: View {
    let weather: WeatherData
    @Environment(\.colorScheme) var colorScheme
    
    // Estimate current temp as midpoint between high and low (or use a better approximation)
    private var currentTemp: Int {
        // Simple approximation: assume current temp is closer to high during day
        // For now, use midpoint
        return (weather.highTemp + weather.lowTemp) / 2
    }
    
    private var tempRange: Int {
        weather.highTemp - weather.lowTemp
    }
    
    private var tempProgress: Double {
        guard tempRange > 0 else { return 0.5 }
        let normalizedCurrent = Double(currentTemp - weather.lowTemp) / Double(tempRange)
        return max(0, min(1, normalizedCurrent))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Weather icon
            Image(systemName: weather.weatherIcon())
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            // Temperature gauge
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    
                    // Temperature range gradient
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 6)
                    }
                    
                    // Current temp indicator
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                        .offset(x: geometry.size.width * tempProgress - 5)
                }
            }
            .frame(height: 10)
            .frame(maxWidth: 80)
            
            // High temp
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("\(weather.highTemp)°")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Low temp
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("\(weather.lowTemp)°")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Precipitation chance
            if weather.precipitationChance > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                    Text("\(weather.precipitationChance)%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    FocusView(focusStore: FocusStore(), streakManager: StreakManager())
}
