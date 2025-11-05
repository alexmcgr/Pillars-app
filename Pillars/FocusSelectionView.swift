//
//  FocusSelectionView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct FocusSelectionView: View {
    @ObservedObject var focusStore: FocusStore
    let choices = FocusChoice.defaultChoices
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Vertical list of focus buttons
            VStack(spacing: 24) {
                ForEach(choices) { choice in
                    FocusButton(
                        choice: choice,
                        action: { selectFocus(choiceId: choice.id) }
                    )
                }
            }
            
            Spacer()
            
            Text("Choose a focus for today")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 30)
        }
        .padding()
    }
    
    private func selectFocus(choiceId: Int) {
        focusStore.setFocus(for: Date(), choiceId: choiceId)
    }
}

struct FocusButton: View {
    let choice: FocusChoice
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
        }
    }
}

#Preview {
    FocusSelectionView(focusStore: FocusStore())
}

