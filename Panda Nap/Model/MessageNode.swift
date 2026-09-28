import SpriteKit

/// A persistent result card with explicit choices for the player.
final class MessageNode: SKNode {
    enum Choice {
        case next
        case retry
        case levels
    }

    private var buttons: [(choice: Choice, node: SKShapeNode)] = []

    init(message: String, detail: String, won: Bool, finalLevel: Bool = false,
         pointScale: CGFloat) {
        super.init()

        let cardSize = CGSize(width: 378 * pointScale, height: 174 * pointScale)
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 22 * pointScale)
        card.fillColor = SKColor(red: 0.10, green: 0.23, blue: 0.16, alpha: 0.97)
        card.strokeColor = SKColor(red: 0.71, green: 0.91, blue: 0.39, alpha: 1)
        card.lineWidth = 2 * pointScale
        addChild(card)

        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = message
        title.fontSize = 27 * pointScale
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position.y = 46 * pointScale
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = detail
        subtitle.fontSize = 15 * pointScale
        subtitle.fontColor = SKColor(red: 0.84, green: 0.95, blue: 0.73, alpha: 1)
        subtitle.verticalAlignmentMode = .center
        subtitle.position.y = 12 * pointScale
        addChild(subtitle)

        let choices: [(Choice, String)]
        if finalLevel {
            choices = [(.levels, "Levels".localized()), (.retry, "Retry".localized())]
        } else if won {
            choices = [(.next, "Next Level".localized()), (.retry, "Retry".localized()),
                       (.levels, "Levels".localized())]
        } else {
            choices = [(.retry, "Retry".localized()), (.levels, "Levels".localized())]
        }
        let spacing: CGFloat = 118 * pointScale
        let firstX = -CGFloat(choices.count - 1) * spacing / 2
        for (index, choice) in choices.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: 110 * pointScale, height: 48 * pointScale),
                                     cornerRadius: 15 * pointScale)
            button.fillColor = index == 0
                ? SKColor(red: 0.39, green: 0.68, blue: 0.22, alpha: 1)
                : SKColor(red: 0.20, green: 0.39, blue: 0.26, alpha: 1)
            button.strokeColor = SKColor(red: 0.73, green: 0.89, blue: 0.56, alpha: 1)
            button.lineWidth = 1.5 * pointScale
            button.position = CGPoint(x: firstX + CGFloat(index) * spacing, y: -48 * pointScale)
            let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            label.text = choice.1
            label.fontSize = 15 * pointScale
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            button.addChild(label)
            addChild(button)
            buttons.append((choice.0, button))
        }

        zPosition = 200
        alpha = 0
        setScale(0.88)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func choice(at scenePoint: CGPoint, in scene: SKScene) -> Choice? {
        let localPoint = convert(scenePoint, from: scene)
        return buttons.first(where: { $0.node.frame.contains(localPoint) })?.choice
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
