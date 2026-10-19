import Foundation

@main
struct LevelCatalogChecks {
    static func main() throws {
        var names = Set<String>()
        for level in 1...16 {
            guard let name = LevelCatalog.name(for: level) else { fatalError("Missing name for level \(level)") }
            precondition(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            precondition(names.insert(name).inserted, "Duplicate puzzle name: \(name)")
            let title = LevelCatalog.title(for: level)
            precondition(title.contains(name), "Title lost its puzzle name")
            precondition(title.contains(String(level)), "Title lost its level number")
        }
        for level in [Int.min, -1, 0, 17, Int.max] {
            precondition(LevelCatalog.name(for: level) == nil, "Unknown level has an authored name")
        }
        precondition(LevelCatalog.title(for: 17) == String(
            format: NSLocalizedString("Level %d", comment: ""), 17))

        // Bonus names already live in the independently authored solution manifest.
        let manifestURL = URL(fileURLWithPath: "tools/bonus_level_solutions.json")
        let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any]
        guard let levels = manifest?["levels"] as? [String: [String: Any]] else {
            fatalError("Missing bonus-level solution manifest")
        }
        for level in 14...16 {
            guard let title = levels[String(level)]?["title"] as? String else {
                fatalError("Missing bonus name for level \(level)")
            }
            precondition(LevelCatalog.name(for: level) == NSLocalizedString(title, comment: ""),
                         "Catalog and authored bonus solution disagree")
        }
        print("Passed catalog coverage, unique names, safe fallback, and bonus-name consistency checks.")
    }
}
