//
//  TodosView.swift
//  Pillars
//
//  Created by Cascade on 11/8/25.
//

import SwiftUI

// MARK: - Todos Detail View
struct TodosDetailView: View {
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var editingTodo: TodoItem?
    
    private var appDay: Date {
        DateUtils.appStartOfDay(for: selectedDate)
    }
    
    private var focusColor: Color {
        focusStore.getTodayColor() ?? .blue
    }
    
    private var todos: [TodoItem] {
        focusStore.getTodos(for: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if todos.isEmpty {
                    VStack(spacing: 16) {
                        Text("No Todos Yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Create your first todo to get started")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(todos) { todo in
                                TodoDetailRow(
                                    todo: todo,
                                    focusStore: focusStore,
                                    selectedDate: selectedDate,
                                    onEdit: {
                                        editingTodo = todo
                                        showingEditSheet = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Todos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingTodo = nil
                        showingEditSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(focusColor)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                TodoEditView(
                    focusStore: focusStore,
                    selectedDate: selectedDate,
                    todo: editingTodo,
                    focusColor: focusColor
                )
            }
        }
    }
}

// MARK: - Todo Detail Row
struct TodoDetailRow: View {
    let todo: TodoItem
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    let onEdit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    focusStore.toggleTodo(for: selectedDate, todoId: todo.id)
                }) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(todo.isCompleted ? .green : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(todo.text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                        .strikethrough(todo.isCompleted)
                    
                    if todo.recurrence != .none || todo.hasReminder {
                        HStack(spacing: 12) {
                            if todo.recurrence != .none {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 12))
                                    Text(todo.recurrence.rawValue)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            if todo.hasReminder, let reminderTime = todo.reminderTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 12))
                                    Text(formatTime(reminderTime))
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.tertiaryBackground(for: colorScheme))
        )
        .alert("Delete Todo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                focusStore.deleteTodo(for: selectedDate, todoId: todo.id)
            }
        } message: {
            Text("Are you sure you want to delete this todo?")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Todo Edit View
struct TodoEditView: View {
    @ObservedObject var focusStore: FocusStore
    let selectedDate: Date
    let todo: TodoItem?
    let focusColor: Color
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var text: String = ""
    @State private var recurrence: TodoRecurrence = .none
    @State private var hasReminder: Bool = false
    @State private var useAMReminder: Bool = false
    @State private var usePMReminder: Bool = false
    @State private var useCustomTime: Bool = false
    @State private var customReminderTime: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Todo", text: $text)
                        .font(.system(size: 16))
                } header: {
                    Text("Title")
                }
                
                Section {
                    Picker("Recurrence", selection: $recurrence) {
                        ForEach(TodoRecurrence.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Repeat")
                } footer: {
                    Text("Recurring todos will appear on the same day each week or month")
                }
                
                Section {
                    Toggle("Enable Reminder", isOn: $hasReminder)
                        .tint(focusColor)
                    
                    if hasReminder {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("AM (\(formatTime(notificationManager.todoAMTime)))", isOn: $useAMReminder)
                                .tint(focusColor)
                                .onChange(of: useAMReminder) { _, newValue in
                                    if newValue {
                                        usePMReminder = false
                                        useCustomTime = false
                                    }
                                }
                            
                            Toggle("PM (\(formatTime(notificationManager.todoPMTime)))", isOn: $usePMReminder)
                                .tint(focusColor)
                                .onChange(of: usePMReminder) { _, newValue in
                                    if newValue {
                                        useAMReminder = false
                                        useCustomTime = false
                                    }
                                }
                            
                            Toggle("Custom Time", isOn: $useCustomTime)
                                .tint(focusColor)
                                .onChange(of: useCustomTime) { _, newValue in
                                    if newValue {
                                        useAMReminder = false
                                        usePMReminder = false
                                    }
                                }
                            
                            if useCustomTime {
                                DatePicker(
                                    "Reminder Time",
                                    selection: $customReminderTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .tint(focusColor)
                            }
                        }
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("Get notified at the selected time. Configure default times in Settings.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(todo == nil ? "New Todo" : "Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTodo()
                        dismiss()
                    }
                    .foregroundColor(focusColor)
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                if let todo = todo {
                    text = todo.text
                    recurrence = todo.recurrence
                    hasReminder = todo.hasReminder
                    
                    if let reminderTime = todo.reminderTime {
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: reminderTime)
                        let amHour = calendar.component(.hour, from: notificationManager.todoAMTime)
                        let pmHour = calendar.component(.hour, from: notificationManager.todoPMTime)
                        
                        if hour == amHour {
                            useAMReminder = true
                        } else if hour == pmHour {
                            usePMReminder = true
                        } else {
                            useCustomTime = true
                            customReminderTime = reminderTime
                        }
                    }
                }
            }
        }
    }
    
    private func saveTodo() {
        let reminderTime: Date? = {
            if !hasReminder { return nil }
            if useAMReminder { return notificationManager.todoAMTime }
            if usePMReminder { return notificationManager.todoPMTime }
            if useCustomTime { return customReminderTime }
            return nil
        }()
        
        var notificationId: String?
        if hasReminder, let reminderTime = reminderTime {
            let todoId = todo?.id.uuidString ?? UUID().uuidString
            notificationId = NotificationManager.shared.scheduleTodoReminder(
                todoId: todoId,
                title: text,
                date: selectedDate,
                reminderTime: reminderTime
            )
        }
        
        let newTodo = TodoItem(
            id: todo?.id ?? UUID(),
            text: text,
            isCompleted: todo?.isCompleted ?? false,
            recurrence: recurrence,
            hasReminder: hasReminder,
            reminderTime: reminderTime,
            notificationId: notificationId
        )
        
        if todo == nil {
            focusStore.setTodos(
                for: selectedDate,
                todos: focusStore.getTodos(for: selectedDate) + [newTodo]
            )
        } else {
            focusStore.updateTodo(for: selectedDate, todo: newTodo)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
