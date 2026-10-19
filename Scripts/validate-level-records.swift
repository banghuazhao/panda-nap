import Foundation

@main
struct LevelRecordChecks {
    static func main() {
        let suite = "PandaNap.RecordChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create test defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(LevelRecordStore.bestRemovals(for: 1, defaults: defaults) == nil)
        precondition(LevelRecordStore.recordWin(level: 1, removals: 4, defaults: defaults))
        precondition(LevelRecordStore.bestRemovals(for: 1, defaults: defaults) == 4)
        precondition(!LevelRecordStore.recordWin(level: 1, removals: 6, defaults: defaults))
        precondition(!LevelRecordStore.recordWin(level: 1, removals: 4, defaults: defaults))
        precondition(LevelRecordStore.recordWin(level: 1, removals: 3, defaults: defaults))
        precondition(LevelRecordStore.bestRemovals(for: 1, defaults: defaults) == 3)
        precondition(LevelRecordStore.bestRemovals(for: 2, defaults: defaults) == nil)
        precondition(LevelRecordStore.recordWin(level: 2, removals: 0, defaults: defaults))
        precondition(LevelRecordStore.bestRemovals(for: 2, defaults: defaults) == 0)
        precondition(!LevelRecordStore.recordWin(level: 2, removals: 1, defaults: defaults))
        precondition(!LevelRecordStore.recordWin(level: 0, removals: 1, defaults: defaults))
        precondition(!LevelRecordStore.recordWin(level: 3, removals: -1, defaults: defaults))
        defaults.set(-3, forKey: "game.bestRemovals.level.3")
        precondition(LevelRecordStore.bestRemovals(for: 3, defaults: defaults) == nil)
        precondition(LevelRecordStore.recordWin(level: 3, removals: 2, defaults: defaults))
        print("Passed 15 personal-best regression checks.")
    }
}
