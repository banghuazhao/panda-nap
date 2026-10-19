import Foundation

/// Winning removal records are independent of level unlocks and tutorial state.
enum LevelRecordStore {
    static func bestRemovals(for level: Int, defaults: UserDefaults = .standard) -> Int? {
        guard level > 0,
              let value = defaults.object(forKey: key(for: level)) as? Int,
              value >= 0 else { return nil }
        return value
    }

    @discardableResult
    static func recordWin(level: Int, removals: Int, defaults: UserDefaults = .standard) -> Bool {
        guard level > 0, removals >= 0 else { return false }
        if let best = bestRemovals(for: level, defaults: defaults), best <= removals { return false }
        defaults.set(removals, forKey: key(for: level))
        return true
    }

    private static func key(for level: Int) -> String { "game.bestRemovals.level.\(level)" }
}
