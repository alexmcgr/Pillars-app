//
//  CardOrderManager.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import Foundation

enum HomeScreenCard: String, Codable, CaseIterable, Identifiable {
    case todo = "To-Do"
    case journal = "Journal Entry"
    case streaks = "Streaks"
    case dateNavigation = "Date Navigation"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .todo: return "checklist"
        case .journal: return "square.and.pencil"
        case .streaks: return "flame.fill"
        case .dateNavigation: return "calendar"
        }
    }
}

class CardOrderManager: ObservableObject {
    static let shared = CardOrderManager()
    
    @Published var cardOrder: [HomeScreenCard] = []
    
    private let userDefaults = UserDefaults.standard
    private let cardOrderKey = "homeScreenCardOrder"
    
    init() {
        loadOrder()
    }
    
    func loadOrder() {
        if let data = userDefaults.data(forKey: cardOrderKey),
           let decoded = try? JSONDecoder().decode([HomeScreenCard].self, from: data) {
            cardOrder = decoded
        } else {
            // Default order (or if decoding failed due to old weather card)
            cardOrder = HomeScreenCard.allCases
        }
    }
    
    func saveOrder() {
        if let encoded = try? JSONEncoder().encode(cardOrder) {
            userDefaults.set(encoded, forKey: cardOrderKey)
        }
    }
    
    func moveCard(from source: IndexSet, to destination: Int) {
        cardOrder.move(fromOffsets: source, toOffset: destination)
        saveOrder()
    }
    
    func resetToDefault() {
        cardOrder = HomeScreenCard.allCases
        saveOrder()
    }
}

