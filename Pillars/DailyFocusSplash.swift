//
//  DailyFocusSplash.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI
import UIKit

extension UIView {
    var allSubviews: [UIView] {
        var subviews = self.subviews
        for subview in self.subviews {
            subviews.append(contentsOf: subview.allSubviews)
        }
        return subviews
    }
}

struct DailyFocusSplash: View {
    @ObservedObject var focusStore: FocusStore
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 0
    @State private var visibleOptionsCount: Int = 0
    @State private var selectedChoice: FocusChoice?
    @State private var isInteractionEnabled = false
    @State private var fadeOutOpacity: Double = 1

    let choices = FocusChoice.defaultChoices

    var body: some View {
        ZStack {
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()
                .onAppear {
                    // Hide tab bar when splash appears
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.allSubviews.forEach { subview in
                            if let tabBar = subview as? UITabBar {
                                tabBar.isHidden = true
                            }
                        }
                    }
                }
                .onDisappear {
                    // Show tab bar when splash disappears
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.allSubviews.forEach { subview in
                            if let tabBar = subview as? UITabBar {
                                tabBar.isHidden = false
                            }
                        }
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                // Title text
                Text("What is your focus today?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Spacer()
                    .frame(height: 60)

                // Focus options
                VStack(spacing: 12) {
                    ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                        if index < visibleOptionsCount {
                            FocusOptionButton(
                                choice: choice,
                                isSelected: selectedChoice?.id == choice.id,
                                isEnabled: isInteractionEnabled,
                                colorScheme: colorScheme,
                                action: {
                                    selectFocus(choice)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .identity
                            ))
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .opacity(fadeOutOpacity)
        .onAppear {
            startAnimation()
            // Pre-fetch weather data during splash screen
            Task {
                _ = try? await WeatherService.shared.fetchWeather()
            }
        }
    }

    private func startAnimation() {
        // Fade in the title text
        withAnimation(.easeOut(duration: 0.8)) {
            titleOpacity = 1
        }

        // Start showing options one by one after title is visible
        let startDelay = 1.2
        let delayBetweenOptions = 0.15

        for index in 0..<choices.count {
            let delay = startDelay + (Double(index) * delayBetweenOptions)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    visibleOptionsCount = index + 1
                    // Move title up as each option appears
                    titleOffset = -20 - (CGFloat(index) * 8)
                }
            }
        }

        // Enable interaction after all animations complete
        let totalAnimationTime = startDelay + (Double(choices.count) * delayBetweenOptions) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime) {
            isInteractionEnabled = true
        }
    }

    private func selectFocus(_ choice: FocusChoice) {
        guard isInteractionEnabled else { return }

        selectedChoice = choice

        // Set the focus for today
        focusStore.setFocus(for: Date(), choiceId: choice.id)

        // Animate selection fade out
        withAnimation(.easeOut(duration: 0.4)) {
            fadeOutOpacity = 0
        }

        // Dismiss after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

struct FocusOptionButton: View {
    let choice: FocusChoice
    let isSelected: Bool
    let isEnabled: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 16) {
                Circle()
                    .fill(choice.color.color)
                    .frame(width: 32, height: 32)

                Text(choice.label)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.tertiaryBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? choice.color.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!isEnabled)
    }
}

