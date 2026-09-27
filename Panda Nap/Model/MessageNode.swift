import SpriteKit

/// A non-physical result card that stays readable above the puzzle.
final class MessageNode: SKNode {
    init(message: String, detail: String, pointScale: CGFloat) {
        super.init()

        let cardSize = CGSize(width: 320 * pointScale, height: 104 * pointScale)
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 22 * pointScale)
        card.fillColor = SKColor(red: 0.10, green: 0.23, blue: 0.16, alpha: 0.94)
        card.strokeColor = SKColor(red: 0.71, green: 0.91, blue: 0.39, alpha: 1)
        card.lineWidth = 2 * pointScale
        addChild(card)

        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = message
        title.fontSize = 28 * pointScale
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position.y = 18 * pointScale
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = detail
        subtitle.fontSize = 16 * pointScale
        subtitle.fontColor = SKColor(red: 0.84, green: 0.95, blue: 0.73, alpha: 1)
        subtitle.verticalAlignmentMode = .center
        subtitle.position.y = -22 * pointScale
        addChild(subtitle)

        zPosition = 200
        alpha = 0
        setScale(0.88)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func appear(reduceMotion: Bool) {
        if reduceMotion {
            setScale(1)
            run(.fadeIn(withDuration: 0.12))
        } else {
            let grow = SKAction.scale(to: 1.04, duration: 0.18)
            grow.timingMode = .easeOut
            let settle = SKAction.scale(to: 1, duration: 0.12)
            settle.timingMode = .easeInEaseOut
            run(.group([.fadeIn(withDuration: 0.12), .sequence([grow, settle])]))
        }
    }
}
