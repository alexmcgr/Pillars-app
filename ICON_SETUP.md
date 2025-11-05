# App Icon Setup Guide

## Overview
The app now dynamically changes its icon based on today's focus color! Here's how to set it up.

## Required Icon Files

You need to add 5 alternate app icons (one for each focus color) to your project.

### Icon Size:
- **256x256 pixels** (or any high-resolution square image)
- iOS will automatically scale them as needed

### File Naming Convention:
- `Blue.png` (Creativity - Blue)
- `Green.png` (Fitness - Green)
- `Red.png` (Relationships - Red)
- `Orange.png` (Entertainment - Orange)
- `Purple.png` (Balance - Purple)

## Step 1: Add Icon Files to Project

1. Export your 5 icon files (256x256 each) with the simple names above
2. Drag and drop all 5 icon files into your Xcode project
3. **IMPORTANT**: When adding, make sure to:
   - ✅ Check "Copy items if needed"
   - ✅ Select "Pillars" target
   - ❌ DO NOT add them to an asset catalog

## Step 2: Verify Info.plist Configuration

The `Info.plist` file has already been created and configured with the alternate icons! You can verify it by:

1. Finding `Info.plist` in the Pillars folder in your project navigator
2. Opening it to view the configuration
3. You should see `CFBundleIcons` → `CFBundleAlternateIcons` with entries for all 5 colors

The configuration is already set up correctly - no manual editing needed! ✅

## Step 3: Test It!

1. Run the app
2. Select a focus for today
3. Go to your home screen
4. The app icon should change to match your focus color! 🎨

## How It Works

- **When you select a focus for today**: Icon changes immediately
- **When you open the app**: Icon updates to match today's focus (if set)
- **If no focus is set**: App uses the default icon

## Troubleshooting

### Icon not changing?
- Make sure icon files are named exactly: `Blue.png`, `Green.png`, `Red.png`, `Orange.png`, `Purple.png`
- Names are case-sensitive!
- Verify files are added to the Pillars target
- Check Info.plist is properly formatted
- Try force-quitting and reopening the app

### Build errors?
- Ensure all 5 icon files exist in your project
- Check that files are not in an asset catalog
- Verify Info.plist XML is valid

## Color Mapping

- **Blue** (0/255, 122/255, 255/255) → Creativity
- **Green** (52/255, 199/255, 89/255) → Fitness
- **Red** (255/255, 59/255, 48/255) → Relationships
- **Orange** (255/255, 149/255, 0/255) → Entertainment
- **Purple** (175/255, 82/255, 222/255) → Balance

