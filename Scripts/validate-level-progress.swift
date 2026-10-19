// Run with:
// swiftc 'Panda Nap/Model/LevelProgress.swift' Scripts/validate-level-progress.swift -o /tmp/panda-progress-check
// /tmp/panda-progress-check
@main
struct LevelProgressChecks {
    static func main() {
        let cases: [(String, Int, Int, Int, Int)] = [
            ("Fresh install", 1, 0, 1, 0),
            ("Legacy progress without completion key", 7, 0, 7, 6),
            ("Current progress", 7, 6, 7, 6),
            ("Replaying does not lose progress", 9, 3, 9, 8),
            ("Last level unlocked but not won", 13, 0, 13, 12),
            ("Last level awaiting completion", 13, 12, 13, 12),
            ("All levels completed", 13, 13, 13, 13),
            ("Invalid negative saved levels", Int.min, Int.min, 1, 0),
            ("Unlocked level outside range", Int.max, 0, 13, 12),
            ("Completion alone cannot unlock levels", 1, Int.max, 1, 0),
            ("Inconsistent partial completion", 6, 6, 6, 5)
        ]
        for (name, unlocked, completed, expectedUnlocked, expectedCompleted) in cases {
            let progress = LevelProgress(unlockedLevel: unlocked, completedLevel: completed, totalLevels: 13)
            precondition(progress.unlockedLevel == expectedUnlocked, "\(name): wrong Continue target")
            precondition(progress.completedLevels == expectedCompleted, "\(name): wrong completion count")
            precondition(progress.allComplete == (expectedCompleted == 13), "\(name): wrong Replay state")
        }
        print("Passed \(cases.count) level progress regression cases.")
    }
}
