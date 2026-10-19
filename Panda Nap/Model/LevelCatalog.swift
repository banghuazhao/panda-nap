import Foundation

/// Stable level numbers remain the save identity; names are presentation only.
enum LevelCatalog {
    private static let names = [
        "Bedtime Basics", "Center Passage", "Wide Crossing", "Overlapping Planks",
        "Staggered Stack", "Left Perch", "Right-Hand Descent", "Upright Balance",
        "From the Left", "Stone Bridge", "Right Perch", "Left-Hand Descent",
        "From the Right", "Quiet Arch", "Double Decker", "Stone Shelter"
    ]

    static func name(for level: Int) -> String? {
        guard (1...names.count).contains(level) else { return nil }
        return NSLocalizedString(names[level - 1], comment: "Authored puzzle name")
    }

    static func title(for level: Int) -> String {
        guard let name = name(for: level) else {
            return String(format: NSLocalizedString("Level %d", comment: "Puzzle number"), level)
        }
        return String(format: NSLocalizedString("Level %d — %@", comment: "Puzzle number and name"), level, name)
    }
}
