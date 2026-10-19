// A read-only snapshot of the existing sequential level progress.
struct LevelProgress {
    let totalLevels: Int
    let unlockedLevel: Int
    let completedLevels: Int

    var allComplete: Bool { completedLevels == totalLevels }

    init(unlockedLevel: Int, completedLevel: Int, totalLevels: Int) {
        self.totalLevels = max(1, totalLevels)
        let clampedUnlockedLevel = min(max(unlockedLevel, 1), self.totalLevels)
        // Completion must match the saved current level exactly. This also
        // migrates a finished former final level when a release adds levels,
        // without trusting completion values far ahead of the unlocked level.
        let finishedCurrentLevel = unlockedLevel >= 1 && unlockedLevel <= self.totalLevels
            && completedLevel == unlockedLevel
        if finishedCurrentLevel {
            self.completedLevels = unlockedLevel
            self.unlockedLevel = unlockedLevel < self.totalLevels ? unlockedLevel + 1 : unlockedLevel
        } else {
            self.unlockedLevel = clampedUnlockedLevel
            // Legacy saves record only the next unlocked level. Reaching the
            // last level alone does not prove that the player finished it.
            self.completedLevels = clampedUnlockedLevel - 1
        }
    }
}
