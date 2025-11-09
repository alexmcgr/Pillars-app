//
//  SettingsView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("dynamicAppIcon") private var dynamicAppIcon = true
    @ObservedObject var focusStore: FocusStore
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cardOrderManager = CardOrderManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) var systemColorScheme

    // State for custom labels
    @State private var customLabels: [Int: String] = [:]
    @State private var showingCardOrderSheet = false

    private var activeColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    private var accentColor: Color {
        focusStore.getTodayColor() ?? Color.blue
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background(for: activeColorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    List {
                        Section {
                            // Theme picker
                            Picker("Theme", selection: $themeManager.appTheme) {
                                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(AppColors.tertiaryBackground(for: activeColorScheme))

                            Toggle(isOn: $dynamicAppIcon) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dynamic App Icon")
                                        .font(.body)
                                        .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                                    Text("Change app icon based on daily focus")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(accentColor)
                            .onChange(of: dynamicAppIcon) { _, newValue in
                                updateAppIcon(enabled: newValue)
                            }
                        } header: {
                            Text("Appearance")
                        }
                        .listRowBackground(AppColors.tertiaryBackground(for: activeColorScheme))

                        Section {
                            NavigationLink(destination: CardOrderView(cardOrderManager: cardOrderManager)) {
                                HStack {
                                    Image(systemName: "square.grid.3x2")
                                        .foregroundColor(accentColor)
                                        .font(.system(size: 20))
                                        .frame(width: 28)
                                    Text("Reorder Home Screen")
                                        .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                                }
                            }
                        } header: {
                            Text("Customization")
                        }
                        .listRowBackground(AppColors.tertiaryBackground(for: activeColorScheme))

                        Section {
                            DatePicker(
                                "Journal Reminder",
                                selection: $notificationManager.notificationTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(accentColor)
                            .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                            
                            DatePicker(
                                "Todo AM Reminder",
                                selection: $notificationManager.todoAMTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(accentColor)
                            .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                            
                            DatePicker(
                                "Todo PM Reminder",
                                selection: $notificationManager.todoPMTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(accentColor)
                            .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                        } header: {
                            Text("Notifications")
                        } footer: {
                            Text("Configure default reminder times for journal and todos")
                                .foregroundColor(AppColors.secondaryText(for: activeColorScheme))
                        }
                        .listRowBackground(AppColors.tertiaryBackground(for: activeColorScheme))

                        Section {
                            ForEach(FocusChoice.defaultChoices) { choice in
                                HStack(spacing: 12) {
                                    // Color indicator
                                    Circle()
                                        .fill(choice.color.color)
                                        .frame(width: 24, height: 24)

                                    // Text field for custom label
                                    TextField(
                                        choice.label,
                                        text: Binding(
                                            get: {
                                                customLabels[choice.id] ?? choice.label
                                            },
                                            set: { newValue in
                                                customLabels[choice.id] = newValue
                                                FocusLabelManager.shared.setLabel(
                                                    for: choice.id,
                                                    label: newValue
                                                )
                                            }
                                        )
                                    )
                                    .foregroundColor(AppColors.primaryText(for: activeColorScheme))
                                    .textFieldStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Category Names")
                        } footer: {
                            Text("Customize the names of your focus categories")
                                .foregroundColor(AppColors.secondaryText(for: activeColorScheme))
                        }
                        .listRowBackground(AppColors.tertiaryBackground(for: activeColorScheme))
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background(for: activeColorScheme))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadCustomLabels()
            }
        }
    }

    private func loadCustomLabels() {
        for choice in FocusChoice.defaultChoices {
            customLabels[choice.id] = FocusLabelManager.shared.getLabel(for: choice.id)
        }
    }

    private func updateAppIcon(enabled: Bool) {
        if enabled {
            // Re-enable dynamic icons - set to today's focus if available
            if let todayFocus = focusStore.getTodayFocus() {
                AppIconManager.shared.setIcon(for: todayFocus.choiceId)
            } else {
                // No focus set, use default icon
                AppIconManager.shared.setIconToDefault()
            }
        } else {
            // Disable dynamic icons - use default/black icon
            AppIconManager.shared.setIconToDefault()
        }
    }
}

// MARK: - Card Order Row
struct CardOrderRow: View {
    let card: HomeScreenCard
    let accentColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.iconName)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
                .frame(width: 28)

            Text(card.rawValue)
                .foregroundColor(AppColors.primaryText(for: colorScheme))

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
        }
        .listRowBackground(AppColors.tertiaryBackground(for: colorScheme))
    }
}

// MARK: - Card Order View
struct CardOrderView: View {
    @ObservedObject var cardOrderManager: CardOrderManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    private var accentColor: Color {
        FocusStore().getTodayColor() ?? .blue
    }

    var body: some View {
        ZStack {
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()

            List {
                Section {
                    ForEach(cardOrderManager.cardOrder, id: \.id) { card in
                        CardOrderRow(
                            card: card,
                            accentColor: accentColor,
                            colorScheme: colorScheme
                        )
                    }
                    .onMove { source, destination in
                        cardOrderManager.moveCard(from: source, to: destination)
                    }
                } header: {
                    Text("Drag to reorder")
                } footer: {
                    Text("The order below will be reflected on your home screen")
                        .foregroundColor(AppColors.secondaryText(for: colorScheme))
                }

                Section {
                    Button(action: {
                        cardOrderManager.resetToDefault()
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset to Default Order")
                                .foregroundColor(accentColor)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppColors.tertiaryBackground(for: colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Reorder Home Screen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(focusStore: FocusStore())
}

