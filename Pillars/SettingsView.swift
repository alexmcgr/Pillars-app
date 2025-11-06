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
    @Environment(\.colorScheme) var systemColorScheme

    // State for custom labels
    @State private var customLabels: [Int: String] = [:]

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

#Preview {
    SettingsView(focusStore: FocusStore())
}

