// Run from the repository root:
// swiftc 'Panda Nap/Model/LevelRecordStore.swift' 'Panda Nap/Model/LevelChallenge.swift' \
//   Scripts/validate-level-challenges.swift -o /tmp/panda-challenge-check
// /tmp/panda-challenge-check
import Foundation

@main
struct LevelChallengeChecks {
    static func main() throws {
        let suite = "PandaNap.ChallengeChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create test defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool) {
            precondition(condition())
            checks += 1
        }

        for level in [-1, 0] + Array(1...13) + [17, Int.max] {
            check(LevelChallenge.targetRemovals(for: level) == nil)
            LevelRecordStore.recordWin(level: level, removals: 0, defaults: defaults)
            check(!LevelChallenge.medalEarned(for: level, defaults: defaults))
        }
        for (level, target) in [(14, 2), (15, 3), (16, 3)] {
            check(LevelChallenge.targetRemovals(for: level) == target)
            check(!LevelChallenge.medalEarned(for: level, defaults: defaults))
            LevelRecordStore.recordWin(level: level, removals: target + 1, defaults: defaults)
            check(!LevelChallenge.medalEarned(for: level, defaults: defaults))
            LevelRecordStore.recordWin(level: level, removals: target, defaults: defaults)
            check(LevelChallenge.medalEarned(for: level, defaults: defaults))
            LevelRecordStore.recordWin(level: level, removals: target + 1, defaults: defaults)
            check(LevelChallenge.medalEarned(for: level, defaults: defaults))
            LevelRecordStore.recordWin(level: level, removals: 0, defaults: defaults)
            check(LevelChallenge.medalEarned(for: level, defaults: defaults))
            defaults.set(-1, forKey: "game.bestRemovals.level.\(level)")
            check(!LevelChallenge.medalEarned(for: level, defaults: defaults))
            defaults.set("invalid", forKey: "game.bestRemovals.level.\(level)")
            check(!LevelChallenge.medalEarned(for: level, defaults: defaults))
        }

        // Optional targets remain tied to the already authored and validated
        // bonus solutions, rather than inventing unverified difficulty goals.
        struct Puzzle: Decodable { let removals: [Removal] }
        struct Removal: Decodable { let node: String }
        struct Manifest: Decodable { let levels: [String: Puzzle] }
        let manifest = try JSONDecoder().decode(
            Manifest.self, from: Data(contentsOf: URL(fileURLWithPath: "tools/bonus_level_solutions.json")))
        for level in [14, 15, 16] {
            check(manifest.levels[String(level)]?.removals.count == LevelChallenge.targetRemovals(for: level))
        }
        // Medals are derived. Reading them must never change any saved data.
        let before = defaults.dictionaryRepresentation()
        for level in 1...16 { _ = LevelChallenge.medalEarned(for: level, defaults: defaults) }
        check(NSDictionary(dictionary: before).isEqual(to: defaults.dictionaryRepresentation()))
        print("Passed \(checks) optional challenge regression checks.")
    }
}
