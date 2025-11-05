//
//  FocusView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct FocusView: View {
    @ObservedObject var focusStore: FocusStore
    
    // macOS dark grey background from the image
    private let backgroundColor = Color(red: 38/255, green: 38/255, blue: 38/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekly calendar view at the top with light gray background
            WeeklyView(focusStore: focusStore)
            
            Spacer()
            
            // Focus selection buttons
            FocusSelectionView(focusStore: focusStore)
            
            Spacer()
        }
        .background(backgroundColor)
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    FocusView(focusStore: FocusStore())
}

