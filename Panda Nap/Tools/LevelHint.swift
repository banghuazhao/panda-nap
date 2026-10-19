import Foundation

/// Optional, authored guidance. Hints describe the layout without changing the puzzle.
enum LevelHint {
    static func text(for level: Int) -> String? {
        let tip: String
        switch level {
        case 1:
            tip = "Panda starts above the bed. Clear the wooden layers without tipping her sideways."
        case 2:
            tip = "The wide top plank rests on two sides. Keep its support balanced as you open the middle."
        case 3:
            tip = "Panda is above the left side of a wide structure. Focus on the path beneath her rather than clearing every block."
        case 4:
            tip = "Panda starts to the right of the bed. Think about how the overlapping planks can bring her toward the center."
        case 5:
            tip = "The square blocks form an offset stack. Removing a lower block changes the balance of everything above it."
        case 6:
            tip = "Panda starts on the left. The two narrow supports under her top block can change which way she leans."
        case 7:
            tip = "Panda rests on the high right plank. The lower planks can help her descend toward the bed."
        case 8:
            tip = "The top block rests on upright planks. Watch how removing one support changes the block's balance."
        case 9:
            tip = "Panda starts far to the left of the bed. A straight drop may miss; use the supporting plank to guide her inward."
        case 10:
            tip = "The gray stone pieces move as one structure. Clear a landing path before removing that support."
        case 11:
            tip = "Panda starts on the right. Compare the two narrow supports before choosing which side to release."
        case 12:
            tip = "Panda rests on the high left plank. Use the lower planks to guide her toward the bed."
        case 13:
            tip = "Panda starts far to the right of the bed. Think about the direction the long plank will tilt."
        case 14:
            tip = "Clear the wooden block above the bed, then remove the top plank."
        case 15:
            tip = "Clear the center block, then remove the upper plank. Let Panda settle before removing the lower plank."
        case 16:
            tip = "Clear the wooden blocks above the bed first. The stone bridge disappears as one piece when tapped."
        default:
            return nil
        }
        return NSLocalizedString(tip, comment: "Optional hint for the current level")
    }
}
