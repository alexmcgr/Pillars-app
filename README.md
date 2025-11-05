# Pillars - Daily Focus Tracker

A simple iOS app for tracking daily focus choices with a weekly calendar view and lockscreen widget.

## Features

1. **Daily Focus Selection**: Choose from up to 5 focus options using large circular buttons
2. **Weekly Calendar View**: See your focus choices for the current week (Sun-Sat) with color-coded labels
3. **Lockscreen Widget**: Small colored circle widget showing your current daily focus
4. **Data Persistence**: All selections are stored locally using UserDefaults with App Group sharing

## Project Structure

### Main App Files
- `PillarsApp.swift` - App entry point
- `ContentView.swift` - Main view container
- `FocusChoice.swift` - Data models for focus choices and color data
- `FocusStore.swift` - Observable object managing focus selections and persistence
- `WeeklyView.swift` - Weekly calendar view component
- `FocusSelectionView.swift` - Focus selection buttons component

### Widget Extension
- `PillarsWidget/PillarsWidget.swift` - Widget implementation
- `PillarsWidget/SharedModels.swift` - Shared data models between app and widget

## Setup Instructions

### Main App
The main app is ready to run! Just build and run in Xcode.

### Widget Extension
See `WIDGET_SETUP.md` for detailed instructions on adding the widget extension to your Xcode project.

**Quick Steps:**
1. Add a Widget Extension target in Xcode
2. Add the files from `PillarsWidget/` folder to the new target
3. Configure App Group capability for both targets: `group.punchline.Pillars`
4. Build and test

## Design Notes

- Colors are inspired by macOS file color codes
- Weekly view shows full-width color blocks for each day
- Focus buttons are arranged in a diamond pattern (5 buttons supported)
- Widget displays as a small circular colored indicator

## Data Storage

- Uses UserDefaults with App Group (`group.punchline.Pillars`) for sharing between app and widget
- Data is keyed by date (yyyy-MM-dd format)
- Selections persist across app launches

