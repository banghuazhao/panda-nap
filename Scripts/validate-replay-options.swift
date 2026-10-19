// Run from the repository root:
// swiftc 'Panda Nap/Model/LevelProgress.swift' 'Panda Nap/Model/LevelRecordStore.swift' \
//   'Panda Nap/Model/LevelChallenge.swift' 'Panda Nap/Model/ReplayOptions.swift' \
//   Scripts/validate-replay-options.swift -o /tmp/panda-replay-options-check
// /tmp/panda-replay-options-check
import Foundation

@main
struct ReplayOptionsChecks {
    static func main() {
        let suite = "PandaNap.ReplayOptionsChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create test defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool) {
            precondition(condition())
            checks += 1
        }
        func levels(_ filter: RecordsFilter, _ progress: LevelProgress) -> [Int] {
            ReplayOptions.visibleLevels(filter: filter, progress: progress, defaults: defaults)
        }

        let fresh = LevelProgress(unlockedLevel: 1, completedLevel: 0, totalLevels: 16)
        check(levels(.all, fresh) == Array(1...16))
        check(levels(.available, fresh) == [1])
        check(levels(.noRecord, fresh) == [1])
        check(levels(.medalsToEarn, fresh).isEmpty)
        check(ReplayOptions.completedLevels(progress: fresh).isEmpty)
        var generator = SeededGenerator(seed: 19)
        check(ReplayOptions.surpriseLevel(progress: fresh, using: &generator) == nil)

        // A record alone cannot make a locked level available or replayable.
        LevelRecordStore.recordWin(level: 14, removals: 0, defaults: defaults)
        check(levels(.noRecord, fresh) == [1])
        check(levels(.medalsToEarn, fresh).isEmpty)
        check(ReplayOptions.surpriseLevel(progress: fresh, using: &generator) == nil)
        defaults.removePersistentDomain(forName: suite)

        let partial = LevelProgress(unlockedLevel: 5, completedLevel: 4, totalLevels: 16)
        LevelRecordStore.recordWin(level: 1, removals: 0, defaults: defaults)
        LevelRecordStore.recordWin(level: 2, removals: 4, defaults: defaults)
        defaults.set(-1, forKey: "game.bestRemovals.level.4")
        check(levels(.available, partial) == [1, 2, 3, 4, 5])
        check(levels(.noRecord, partial) == [3, 4, 5])
        check(levels(.medalsToEarn, partial).isEmpty)
        check(ReplayOptions.completedLevels(progress: partial) == [1, 2, 3, 4])
        // A filtered row must retain its real level ID (first result is level3).
        check(levels(.noRecord, partial).first == 3)

        defaults.removePersistentDomain(forName: suite)
        let legacy = LevelProgress(unlockedLevel: 13, completedLevel: 13, totalLevels: 16)
        check(levels(.available, legacy) == Array(1...14))
        check(levels(.noRecord, legacy) == Array(1...14))
        check(levels(.medalsToEarn, legacy) == [14])
        check(ReplayOptions.completedLevels(progress: legacy) == Array(1...13))

        let bonus = LevelProgress(unlockedLevel: 16, completedLevel: 15, totalLevels: 16)
        LevelRecordStore.recordWin(level: 14, removals: 4, defaults: defaults)
        LevelRecordStore.recordWin(level: 15, removals: 3, defaults: defaults)
        check(levels(.medalsToEarn, bonus) == [14, 16])
        check(levels(.noRecord, bonus) == Array(1...13) + [16])
        LevelRecordStore.recordWin(level: 14, removals: 2, defaults: defaults)
        check(levels(.medalsToEarn, bonus) == [16])
        LevelRecordStore.recordWin(level: 16, removals: 0, defaults: defaults)
        check(levels(.medalsToEarn, bonus).isEmpty)
        check(levels(.noRecord, bonus) == Array(1...13))
        // Even a winning record for level16 must not bypass completed progress.
        check(ReplayOptions.completedLevels(progress: bonus) == Array(1...15))

        let complete = LevelProgress(unlockedLevel: 16, completedLevel: 16, totalLevels: 16)
        check(ReplayOptions.completedLevels(progress: complete) == Array(1...16))
        check(levels(.all, complete) == levels(.available, complete))
        let invalid = LevelProgress(unlockedLevel: Int.max, completedLevel: Int.max, totalLevels: 16)
        check(ReplayOptions.completedLevels(progress: invalid) == Array(1...15))
        let single = LevelProgress(unlockedLevel: 1, completedLevel: 1, totalLevels: 1)
        check(ReplayOptions.surpriseLevel(progress: single, using: &generator) == 1)

        // Exercise many actual random draws against the completed bounds,
        // without a flaky expectation about random coverage or frequencies.
        let before = defaults.dictionaryRepresentation()
        for progress in [partial, legacy, bonus, complete, invalid] {
            let completed = Set(ReplayOptions.completedLevels(progress: progress))
            let samples = (0..<100).compactMap { _ in
                ReplayOptions.surpriseLevel(progress: progress, using: &generator)
            }
            check(samples.count == 100)
            check(samples.allSatisfy { completed.contains($0) && $0 <= progress.unlockedLevel })
            for filter in RecordsFilter.allCases { _ = levels(filter, progress) }
        }
        check(NSDictionary(dictionary: before).isEqual(to: defaults.dictionaryRepresentation()))
        print("Passed \(checks) replay filter and surprise replay regression checks (500 random draws).")
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var seed: UInt64

    mutating func next() -> UInt64 {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return seed
    }
}
