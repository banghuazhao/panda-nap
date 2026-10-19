// A read-only snapshot of the existing sequential level progress.
struct LevelProgress {
    let totalLevels: Int
    let unlockedLevel: Int
    let completedLevels: Int

    var allComplete: Bool { completedLevels == totalLevels }

    init(unlockedLevel: Int, completedLevel: Int, totalLevels: Int) {
        self.totalLevels = max(1, totalLevels)
        self.unlockedLevel = min(max(unlockedLevel, 1), self.totalLevels)
        // Older saves only record the next unlocked level. Unlocking the last
        // level does not mean it has been completed. A completion value beyond
        // the unlocked level must not unlock content or inflate the counter.
        let finishedFinalLevel = self.unlockedLevel == self.totalLevels && completedLevel >= self.totalLevels
        self.completedLevels = finishedFinalLevel ? self.totalLevels : self.unlockedLevel - 1
    }
}
