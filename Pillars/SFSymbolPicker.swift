//
//  SFSymbolPicker.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import SwiftUI

struct SFSymbolPicker: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    
    // Categorized SF Symbols
    let categories: [(String, [String])] = [
        ("Fitness & Health", [
            "figure.run", "figure.walk", "figure.strengthtraining.traditional",
            "figure.yoga", "figure.cooldown", "figure.mind.and.body",
            "figure.core.training", "figure.outdoor.cycle", "figure.rower",
            "flame", "heart.fill", "bolt.heart.fill", "drop.fill",
            "leaf.fill", "bed.double.fill", "lungs.fill"
        ]),
        ("Creative & Learning", [
            "pencil.and.outline", "paintpalette.fill", "camera.fill",
            "film.fill", "music.note", "guitars", "book.fill",
            "theatermasks.fill", "paintbrush.fill", "brain.head.profile",
            "graduationcap.fill", "lightbulb.fill", "hand.wave.fill", "mic.fill"
        ]),
        ("Daily Habits & Mindfulness", [
            "sunrise.fill", "sunset.fill", "moon.fill", "sparkles",
            "hands.sparkles.fill", "timer", "calendar", "checkmark.circle.fill",
            "square.and.pencil", "bubble.left.and.bubble.right.fill",
            "text.book.closed.fill", "leaf.arrow.circlepath"
        ]),
        ("Life & Home", [
            "cup.and.saucer.fill", "fork.knife", "cart.fill", "house.fill",
            "washer.fill", "dog.fill", "bolt.house.fill", "car.fill", "bicycle",
            "globe.europe.africa.fill", "takeoutbag.and.cup.and.straw.fill"
        ]),
        ("Work & Productivity", [
            "laptopcomputer", "desktopcomputer", "keyboard",
            "rectangle.and.pencil.and.ellipsis", "doc.text.fill",
            "calendar.badge.checkmark", "brain", "chart.line.uptrend.xyaxis",
            "hourglass", "network", "folder.fill", "paperclip", "mail.fill"
        ]),
        ("Generic", [
            "circle.fill", "square.fill", "star.fill", "heart",
            "flame.fill", "infinity", "sparkle.magnifyingglass", "target",
            "bolt.fill", "arrow.triangle.2.circlepath", "seal.fill",
            "rosette", "medal.fill"
        ])
    ]
    
    var filteredCategories: [(String, [String])] {
        if searchText.isEmpty {
            return categories
        }
        return categories.compactMap { category, icons in
            let filtered = icons.filter { $0.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : (category, filtered)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(AppColors.primaryText(for: colorScheme))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.tertiaryBackground(for: colorScheme))
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // Categories
                        ForEach(filteredCategories, id: \.0) { category, icons in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                
                                LazyVGrid(
                                    columns: [
                                        GridItem(.adaptive(minimum: 60), spacing: 8)
                                    ],
                                    spacing: 8
                                ) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                            dismiss()
                                        }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: icon)
                                                    .font(.system(size: 28))
                                                    .foregroundColor(
                                                        selectedIcon == icon ?
                                                            .white : AppColors.primaryText(for: colorScheme)
                                                    )
                                                    .frame(width: 60, height: 60)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(
                                                                selectedIcon == icon ?
                                                                    Color.blue :
                                                                    AppColors.tertiaryBackground(for: colorScheme)
                                                            )
                                                    )
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        if filteredCategories.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No icons found")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                }
            }
        }
    }
}

