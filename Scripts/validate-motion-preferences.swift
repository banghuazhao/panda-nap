import Foundation

@main
struct MotionPreferenceChecks {
    static func main() {
        for (app, system, expected) in [(false, false, false), (true, false, true),
                                         (false, true, true), (true, true, true)] {
            precondition(MotionPreferences.reduceMotionEnabled(appPreference: app,
                                                               systemPreference: system) == expected)
        }
        let suite = "PandaNap.MotionChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create test defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(!MotionPreferences.appEnabled(defaults: defaults))
        defaults.set(4, forKey: "BEST_LEVEL")
        defaults.set(3, forKey: "COMPLETED_LEVEL")
        defaults.set(false, forKey: "game.musicEnabled")
        defaults.set(0.25, forKey: "game.musicVolume")
        MotionPreferences.setAppEnabled(true, defaults: defaults)
        precondition(MotionPreferences.appEnabled(defaults: defaults))
        MotionPreferences.setAppEnabled(false, defaults: defaults)
        precondition(!MotionPreferences.appEnabled(defaults: defaults))
        precondition(MotionPreferences.reduceMotionEnabled(
            appPreference: MotionPreferences.appEnabled(defaults: defaults), systemPreference: true))
        let invalidValues: [Any] = ["true", 1, [true]]
        for invalid in invalidValues {
            defaults.set(invalid, forKey: MotionPreferences.defaultsKey)
            precondition(!MotionPreferences.appEnabled(defaults: defaults))
        }
        precondition(defaults.integer(forKey: "BEST_LEVEL") == 4)
        precondition(defaults.integer(forKey: "COMPLETED_LEVEL") == 3)
        precondition(!defaults.bool(forKey: "game.musicEnabled"))
        precondition(defaults.double(forKey: "game.musicVolume") == 0.25)
        print("Passed motion precedence, persistence, invalid-value, and unrelated-save preservation checks.")
    }
}
