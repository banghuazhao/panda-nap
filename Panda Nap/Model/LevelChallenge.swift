import Foundation

/// Optional removal targets are separate from level progression. Only levels
/// with verified winning solutions receive a target.
enum LevelChallenge {
    static func targetRemovals(for level: Int) -> Int? {
        switch level {
        case 14: return 2
        case 15, 16: return 3
        default: return nil
        }
    }

    static func medalEarned(for level: Int, defaults: UserDefaults = .standard) -> Bool {
        guard let target = targetRemovals(for: level),
              let best = LevelRecordStore.bestRemovals(for: level, defaults: defaults) else { return false }
        return best <= target
    }
}
