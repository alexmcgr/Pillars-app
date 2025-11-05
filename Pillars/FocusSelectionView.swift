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
    let choices = FocusChoice.defaultChoices

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Vertical list of focus buttons
            VStack(spacing: 24) {
                ForEach(choices) { choice in
                    FocusButton(
                        choice: choice,
                        isSelected: selectedFocusId == choice.id,
                        action: { selectFocus(choiceId: choice.id) }
                    )
                }
            }
        }
        .padding()
    }

    private func selectFocus(choiceId: Int) {
        focusStore.setFocus(for: selectedDate, choiceId: choiceId)
    }
}

struct FocusButton: View {
    let choice: FocusChoice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Small circle icon on the left
                Circle()
                    .fill(choice.color.color)
                    .frame(width: 40, height: 40)

                // Label on the right
                Text(choice.label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
        }
    }
}

#Preview {
    FocusSelectionView(focusStore: FocusStore())
}
