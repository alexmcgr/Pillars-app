# Widget Extension Setup Instructions

The widget extension files have been created, but you'll need to add them to your Xcode project as a separate target. Here's how:

## Steps to Add Widget Extension:

1. **Open Xcode Project**
   - Open `Pillars.xcodeproj` in Xcode

2. **Add Widget Extension Target**
   - In Xcode, go to **File → New → Target**
   - Select **Widget Extension** (under iOS)
   - Name it `PillarsWidget`
   - Make sure "Include Configuration Intent" is **unchecked** (we're using a simple static widget)
   - Click **Finish**

3. **Replace Generated Files**
   - Delete the auto-generated `PillarsWidget.swift` file in the new target
   - Add the files from `PillarsWidget/` folder to the new target:
     - `PillarsWidget.swift`
     - `SharedModels.swift`

4. **Configure App Group**
   - Select your main **Pillars** target
   - Go to **Signing & Capabilities** tab
   - Click **+ Capability**
   - Add **App Groups**
   - Create/select group: `group.punchline.Pillars`
   
   - Now select the **PillarsWidget** target
   - Add the same **App Groups** capability
   - Select the same group: `group.punchline.Pillars`

5. **Build and Test**
   - Build the project (⌘B)
   - Run the app and select a focus
   - Add the widget to your lock screen by long-pressing the lock screen and tapping the customize button

## Notes:

- The widget will show a colored circle matching your current daily focus
- Data is shared between the app and widget via App Group UserDefaults
- The widget refreshes at midnight each day

