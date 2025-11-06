//
//  FocusMenuButton.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct FocusMenuButton: View {
    @ObservedObject var focusStore: FocusStore
    var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    var body: some View {
        Menu {
            ForEach(FocusChoice.defaultChoices) { choice in
                Button(action: {
                    focusStore.setFocus(for: selectedDate, choiceId: choice.id)
                }) {
                    HStack {
                        Circle()
                            .fill(choice.color.color)
                            .frame(width: 10, height: 10)
                        Text(choice.label)
                        if selectedFocusId == choice.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)

                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
            }
        }
    }
}

