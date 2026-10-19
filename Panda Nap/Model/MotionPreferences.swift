import Foundation
import CoreFoundation

/// The app choice can add reduced motion, and can never override the system choice.
enum MotionPreferences {
    static let defaultsKey = "game.calmerAnimations"

    static func appEnabled(defaults: UserDefaults = .standard) -> Bool {
        guard let value = defaults.object(forKey: defaultsKey) as? NSNumber,
              CFGetTypeID(value) == CFBooleanGetTypeID() else { return false }
        return value.boolValue
    }

    static func setAppEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: defaultsKey)
    }

    static func reduceMotionEnabled(appPreference: Bool, systemPreference: Bool) -> Bool {
        appPreference || systemPreference
    }
}
