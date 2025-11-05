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

    // State for custom labels
    @State private var customLabels: [Int: String] = [:]

    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    List {
                        Section {
                            Toggle(isOn: $dynamicAppIcon) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dynamic App Icon")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Text("Change app icon based on daily focus")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .tint(Color(red: 0/255, green: 122/255, blue: 255/255))
                            .onChange(of: dynamicAppIcon) { _, newValue in
                                updateAppIcon(enabled: newValue)
                            }
                        } header: {
                            Text("Appearance")
                        }
                        .listRowBackground(Color(red: 58/255, green: 58/255, blue: 58/255))

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
                                    .foregroundColor(.white)
                                    .textFieldStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Category Names")
                        } footer: {
                            Text("Customize the names of your focus categories")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(red: 58/255, green: 58/255, blue: 58/255))
                    }
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
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

