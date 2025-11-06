//
//  FocusGradientBackground.swift
//  Pillars
//
//  Created by Alex McGregor on 11/5/25.
//

import SwiftUI

struct FocusGradientBackground: View {
    let focusColor: Color?
    let colorScheme: ColorScheme

    var body: some View {
        ZStack(alignment: .top) {
            // Base background
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()

            // Gradient overlay - fixed height for consistent appearance
            if let color = focusColor {
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(colorScheme == .dark ? 0.35 : 0.50),
                        color.opacity(colorScheme == .dark ? 0.25 : 0.35),
                        color.opacity(colorScheme == .dark ? 0.15 : 0.20),
                        AppColors.background(for: colorScheme).opacity(0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }
        }
    }
}

