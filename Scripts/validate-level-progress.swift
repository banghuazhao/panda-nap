// Run with:
// swiftc 'Panda Nap/Model/LevelProgress.swift' Scripts/validate-level-progress.swift -o /tmp/panda-progress-check
// /tmp/panda-progress-check
@main
struct LevelProgressChecks {
    static func main() {
        let cases: [(String, Int, Int, Int, Int, Int)] = [
            // Name, saved unlock, saved completion, available levels, expected unlock, expected completion.
            ("Fresh install", 1, 0, 16, 1, 0),
            ("Legacy progress without completion key", 7, 0, 16, 7, 6),
            ("Current progress", 7, 6, 16, 7, 6),
            ("Replaying does not lose progress", 9, 3, 16, 9, 8),
            ("Former last level unlocked but not won", 13, 0, 16, 13, 12),
            ("Former last level awaiting completion", 13, 12, 16, 13, 12),
            ("Former last level completed unlocks new content", 13, 13, 16, 14, 13),
            ("Migrated former final completion is stable", 14, 13, 16, 14, 13),
            ("Finished current level unlocks exactly one next level", 6, 6, 16, 7, 6),
            ("Current last level unlocked but not won", 16, 0, 16, 16, 15),
            ("Current last level awaiting completion", 16, 15, 16, 16, 15),
            ("All levels completed", 16, 16, 16, 16, 16),
            ("Old release final completion", 13, 13, 13, 13, 13),
            ("Invalid negative saved levels", Int.min, Int.min, 16, 1, 0),
            ("Invalid zero unlock cannot use completion", 0, 0, 16, 1, 0),
            ("Invalid negative unlock cannot use completion", -1, -1, 16, 1, 0),
            ("Unlocked level outside range", Int.max, 0, 16, 16, 15),
            ("Matching invalid saved levels cannot prove completion", Int.max, Int.max, 16, 16, 15),
            ("Completion alone cannot unlock levels", 1, Int.max, 16, 1, 0),
            ("Completion ahead by one cannot unlock levels", 6, 7, 16, 6, 5),
            ("Completion far ahead cannot unlock levels", 6, 16, 16, 6, 5),
            ("Corrupt final completion cannot finish game", 16, Int.max, 16, 16, 15),
            ("Downgrade stays in the available level range", 16, 16, 13, 13, 12),
            ("Invalid level total is safe", 1, 0, Int.min, 1, 0),
            ("Largest current level does not overflow", Int.max, Int.max, Int.max, Int.max, Int.max),
            ("Largest next unlock does not overflow", Int.max - 1, Int.max - 1, Int.max, Int.max, Int.max - 1)
        ]
        for (name, unlocked, completed, total, expectedUnlocked, expectedCompleted) in cases {
            let progress = LevelProgress(unlockedLevel: unlocked, completedLevel: completed, totalLevels: total)
            precondition(progress.unlockedLevel == expectedUnlocked, "\(name): wrong Continue target")
            precondition(progress.completedLevels == expectedCompleted, "\(name): wrong completion count")
            precondition(progress.allComplete == (expectedCompleted == max(1, total)), "\(name): wrong Replay state")
            precondition((1...progress.totalLevels).contains(progress.unlockedLevel), "\(name): unlocked level outside range")
            precondition((0...progress.totalLevels).contains(progress.completedLevels), "\(name): completion outside range")
            let restored = LevelProgress(unlockedLevel: progress.unlockedLevel,
                                         completedLevel: progress.completedLevels,
                                         totalLevels: total)
            precondition(restored.unlockedLevel == progress.unlockedLevel,
                         "\(name): reopening advances more than one level")
            precondition(restored.completedLevels == progress.completedLevels,
                         "\(name): reopening loses completion")
        }
        print("Passed \(cases.count) level progress regression cases.")
    }
}
