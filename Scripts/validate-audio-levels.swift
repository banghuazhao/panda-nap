import Foundation

@main
struct AudioLevelChecks {
    static func main() {
        let cases: [(String, Any?, Float)] = [
            ("Missing preference", nil, 1),
            ("Invalid text", "quiet", 1),
            ("Invalid boolean", false, 1),
            ("Invalid collection", [0.5], 1),
            ("Zero", 0, 0),
            ("Full volume", 1, 1),
            ("Fraction", 0.25, 0.25),
            ("Negative volume", -0.5, 0),
            ("Volume above range", 4, 1),
            ("Largest finite number", Double.greatestFiniteMagnitude, 1),
            ("NaN", Double.nan, 1),
            ("Positive infinity", Double.infinity, 1),
            ("Negative infinity", -Double.infinity, 1)
        ]
        for (name, value, expected) in cases {
            precondition(AudioLevels.normalized(value) == expected, name)
        }

        let suite = "PandaNap.AudioChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create test defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(AudioLevels.volume(for: .music, defaults: defaults) == 1)
        precondition(AudioLevels.volume(for: .effects, defaults: defaults) == 1)
        defaults.set(false, forKey: "game.musicEnabled")
        defaults.set(true, forKey: "game.effectsEnabled")
        AudioLevels.setVolume(0.25, for: .music, defaults: defaults)
        precondition(AudioLevels.volume(for: .music, defaults: defaults) == 0.25)
        precondition(AudioLevels.volume(for: .effects, defaults: defaults) == 1)
        AudioLevels.setVolume(0.75, for: .effects, defaults: defaults)
        precondition(AudioLevels.volume(for: .music, defaults: defaults) == 0.25)
        precondition(AudioLevels.volume(for: .effects, defaults: defaults) == 0.75)
        precondition(!defaults.bool(forKey: "game.musicEnabled"))
        precondition(defaults.bool(forKey: "game.effectsEnabled"))
        defaults.set("invalid", forKey: AudioLevels.Channel.effects.defaultsKey)
        precondition(AudioLevels.volume(for: .effects, defaults: defaults) == 1)
        precondition(AudioLevels.setVolume(.nan, for: .music, defaults: defaults) == 1)
        precondition(AudioLevels.volume(for: .music, defaults: defaults) == 1)
        precondition(AudioLevels.setVolume(-1, for: .effects, defaults: defaults) == 0)
        precondition(AudioLevels.volume(for: .effects, defaults: defaults) == 0)
        print("Passed \(cases.count) audio normalization cases and channel persistence checks.")
    }
}
