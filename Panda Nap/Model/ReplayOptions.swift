import Foundation

enum RecordsFilter: String, CaseIterable {
    case all = "All"
    case available = "Available"
    case noRecord = "No record"
    case medalsToEarn = "Medals to earn"
}

/// Replay choices never unlock a level or infer completion from a record.
enum ReplayOptions {
    static func visibleLevels(filter: RecordsFilter, progress: LevelProgress,
                              defaults: UserDefaults = .standard) -> [Int] {
        (1...progress.totalLevels).filter { level in
            switch filter {
            case .all: return true
            case .available: return level <= progress.unlockedLevel
            case .noRecord:
                return level <= progress.unlockedLevel
                    && LevelRecordStore.bestRemovals(for: level, defaults: defaults) == nil
            case .medalsToEarn:
                return level <= progress.unlockedLevel
                    && LevelChallenge.targetRemovals(for: level) != nil
                    && !LevelChallenge.medalEarned(for: level, defaults: defaults)
            }
        }
    }

    static func completedLevels(progress: LevelProgress) -> [Int] {
        guard progress.completedLevels > 0 else { return [] }
        return Array(1...progress.completedLevels)
    }

    static func surpriseLevel(progress: LevelProgress) -> Int? {
        var generator = SystemRandomNumberGenerator()
        return surpriseLevel(progress: progress, using: &generator)
    }

    static func surpriseLevel<Generator: RandomNumberGenerator>(
        progress: LevelProgress, using generator: inout Generator
    ) -> Int? {
        completedLevels(progress: progress).randomElement(using: &generator)
    }
}
