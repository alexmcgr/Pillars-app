//
//  FocusSelectionView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct FocusSelectionView: View {
    @ObservedObject var focusStore: FocusStore
    var selectedDate: Date = Date()
    var onSelection: (() -> Void)? = nil
    let choices = FocusChoice.defaultChoices
    @Environment(\.colorScheme) var colorScheme

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                FocusButton(
                    choice: choice,
                    isSelected: selectedFocusId == choice.id,
                    colorScheme: colorScheme,
                    isLast: index == choices.count - 1,
                    action: { selectFocus(choiceId: choice.id) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func selectFocus(choiceId: Int) {
        focusStore.setFocus(for: selectedDate, choiceId: choiceId)
        onSelection?()
    }
}

struct FocusButton: View {
    let choice: FocusChoice
    let isSelected: Bool
    let colorScheme: ColorScheme
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Color circle indicator
                Circle()
                    .fill(choice.color.color)
                    .frame(width: 12, height: 12)

                // Label
                Text(choice.label)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))

                Spacer()

                // Checkmark if selected
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(choice.color.color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? choice.color.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

#Preview {
    FocusSelectionView(focusStore: FocusStore())
}
