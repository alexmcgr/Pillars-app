//
//  PillarsWidget.swift
//  PillarsWidget
//
//  Created by Alex McGregor on 11/4/25.
//

import WidgetKit
import SwiftUI

@main
struct PillarsWidget: Widget {
    let kind: String = "PillarsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusProvider()) { entry in
            PillarsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Focus")
        .description("Shows your current daily focus color.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct FocusProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusEntry {
        FocusEntry(date: Date(), color: Color.gray)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> ()) {
        let entry = FocusEntry(date: Date(), color: getCurrentFocusColor())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> ()) {
        let currentDate = Date()
        let entry = FocusEntry(date: currentDate, color: getCurrentFocusColor())
        
        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
    
    private func getCurrentFocusColor() -> Color {
        // Access shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.punchline.Pillars")
        guard let data = sharedDefaults?.data(forKey: "focusSelections"),
              let selections = try? JSONDecoder().decode([String: DailyFocus].self, from: data) else {
            return Color.gray
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())
        
        guard let todayFocus = selections[todayKey],
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == todayFocus.choiceId }) else {
            return Color.gray
        }
        
        return Color(red: choice.color.red, green: choice.color.green, blue: choice.color.blue, opacity: choice.color.alpha)
    }
}

struct FocusEntry: TimelineEntry {
    let date: Date
    let color: Color
}

struct PillarsWidgetEntryView: View {
    var entry: FocusProvider.Entry
    
    var body: some View {
        Circle()
            .fill(entry.color)
            .frame(width: 44, height: 44)
    }
}

#Preview(as: .accessoryCircular) {
    PillarsWidget()
} timeline: {
    FocusEntry(date: .now, color: .blue)
    FocusEntry(date: .now, color: .green)
}

