import UIKit

class AppIconManager {
    static let shared = AppIconManager()

    private init() {}

    // Icon names matching the focus choices
    private let iconNames: [Int: String?] = [
        0: "Blue",      // Creativity
        1: "Green",     // Fitness
        2: "Red",       // Relationships
        3: "Orange",    // Entertainment
        4: "Purple"     // Balance
    ]

    func setIcon(for focusChoiceId: Int) {
        // Check if dynamic icons are enabled
        let dynamicIconEnabled = UserDefaults.standard.bool(forKey: "dynamicAppIcon")
        guard dynamicIconEnabled else {
            // Dynamic icons disabled, use default icon
            setIconToDefault()
            return
        }

        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported")
            return
        }

        let iconName = iconNames[focusChoiceId] ?? nil

        // Avoid setting the icon if it's already the current one
        if UIApplication.shared.alternateIconName == iconName {
            return
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error setting alternate icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to \(iconName ?? "Primary")")
            }
        }
    }

    func setIconToDefault() {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported")
            return
        }

        // nil means use the primary/default icon
        if UIApplication.shared.alternateIconName == nil {
            return // Already using default icon
        }

        UIApplication.shared.setAlternateIconName(nil) { error in
            if let error = error {
                print("Error setting default icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to Primary")
            }
        }
    }
}
