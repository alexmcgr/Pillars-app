# Pillars - Daily Focus Tracker

A simple iOS app for tracking daily focus choices with a weekly calendar view, journaling, and dynamic app icons.

## Features

1. **Daily Focus Selection**: Choose from up to 5 focus options using large circular buttons
2. **Weekly Calendar View**: See your focus choices for the current week (Sun-Sat) with color-coded labels
3. **Monthly Calendar View**: Full month view with journal entry indicators and navigation
4. **Journaling**: Add quick notes to specific dates
5. **Dynamic App Icon**: App icon changes based on your daily focus
6. **Customizable Categories**: Rename focus categories to match your needs
7. **Data Persistence**: All selections are stored locally using UserDefaults

## Project Structure

### Main App Files
- `PillarsApp.swift` - App entry point
- `ContentView.swift` - Main view container
- `FocusChoice.swift` - Data models for focus choices and color data
- `FocusStore.swift` - Observable object managing focus selections and persistence
- `WeeklyView.swift` - Weekly calendar view component
- `FocusSelectionView.swift` - Focus selection buttons component

## Setup Instructions

The app is ready to run! Just build and run in Xcode.

### App Icons Setup
See `ICON_SETUP.md` for instructions on adding alternate app icon files.

## Design Notes

- Colors are inspired by macOS file color codes
- Weekly view shows full-width color blocks for each day
- Focus buttons are arranged in a diamond pattern (5 buttons supported)
- Monthly calendar view with interactive month navigation
- Journal entries are displayed with date and focus information

## Data Storage

- Uses UserDefaults for local data persistence
- Data is keyed by date (yyyy-MM-dd format)
- Selections and journal entries persist across app launches

