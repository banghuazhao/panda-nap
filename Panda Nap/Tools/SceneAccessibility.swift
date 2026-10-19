import SpriteKit
import UIKit

/// Explicit accessibility for SpriteKit content, with live screen geometry.
@MainActor
enum SceneAccessibility {
    struct Item {
        weak var node: SKNode?
        let label: String
        let value: (() -> String?)?
        let hint: String?
        let traits: UIAccessibilityTraits
        let isEnabled: (() -> Bool)?
        let activate: (() -> Bool)?
        let increment: (() -> Void)?
        let decrement: (() -> Void)?

        init(node: SKNode, label: String, value: (() -> String?)? = nil,
             hint: String? = nil, traits: UIAccessibilityTraits = .button,
             isEnabled: (() -> Bool)? = nil, activate: (() -> Bool)? = nil,
             increment: (() -> Void)? = nil, decrement: (() -> Void)? = nil) {
            self.node = node
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
            self.isEnabled = isEnabled
            self.activate = activate
            self.increment = increment
            self.decrement = decrement
        }
    }

    static func install(on view: SKView, scene: SKScene, items: [Item]) {
        let container = Container(view: view, scene: scene, items: items)
        view.isAccessibilityElement = false
        scene.isAccessibilityElement = false
        // A dynamic container filters offscreen map nodes whenever VoiceOver
        // queries its children. No frame polling or render-loop work is needed.
        // SpriteKit owns SKView's children and exposes its current scene.
        scene.accessibilityElements = [container]
    }

    static func clear(from view: SKView, scene: SKScene) {
        guard let container = scene.accessibilityElements?.first as? Container,
              container.scene === scene else { return }
        scene.accessibilityElements = []
    }

    static func announceScene(on view: SKView, scene: SKScene) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak view, weak scene] in
            guard let view, let scene, view.scene === scene, !scene.isPaused,
                  view.window != nil,
                  view.window?.rootViewController?.presentedViewController == nil else { return }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    private final class Container: UIAccessibilityElement {
        weak var scene: SKScene?
        private weak var view: SKView?
        private var elements = [Element]()

        init(view: SKView, scene: SKScene, items: [Item]) {
            self.scene = scene
            self.view = view
            super.init(accessibilityContainer: scene)
            isAccessibilityElement = false
            elements = items.map { Element(container: self, view: view, scene: scene, item: $0) }
        }

        override var accessibilityFrame: CGRect {
            get {
                guard let view, let scene, view.scene === scene else { return .zero }
                return UIAccessibility.convertToScreenCoordinates(view.bounds, in: view)
            }
            set { }
        }

        private var visibleElements: [Element] {
            elements.filter { !$0.accessibilityFrame.isEmpty }
        }

        override func accessibilityElementCount() -> Int { visibleElements.count }

        override func accessibilityElement(at index: Int) -> Any? {
            let visible = visibleElements
            guard visible.indices.contains(index) else { return nil }
            return visible[index]
        }

        override func index(ofAccessibilityElement element: Any) -> Int {
            guard let element = element as? Element else { return NSNotFound }
            return visibleElements.firstIndex(where: { $0 === element }) ?? NSNotFound
        }
    }

    private final class Element: UIAccessibilityElement {
        private weak var view: SKView?
        private weak var scene: SKScene?
        private let item: Item

        init(container: Container, view: SKView, scene: SKScene, item: Item) {
            self.view = view
            self.scene = scene
            self.item = item
            super.init(accessibilityContainer: container)
            isAccessibilityElement = true
            accessibilityLabel = item.label
            accessibilityHint = item.hint
        }

        override var accessibilityValue: String? {
            get { item.value?() }
            set { }
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            get {
                var traits = item.traits
                if item.isEnabled?() == false { traits.insert(.notEnabled) }
                return traits
            }
            set { }
        }

        override var accessibilityFrame: CGRect {
            get {
                guard let view, let scene, view.scene === scene,
                      view.window != nil, !view.isHidden, view.alpha > 0.01,
                      let node = item.node, let parent = node.parent,
                      isVisible(node, in: scene) else { return .zero }
                let frame = node.calculateAccumulatedFrame()
                guard frame.isFinite, !frame.isEmpty else { return .zero }
                let corners = [CGPoint(x: frame.minX, y: frame.minY),
                               CGPoint(x: frame.minX, y: frame.maxY),
                               CGPoint(x: frame.maxX, y: frame.minY),
                               CGPoint(x: frame.maxX, y: frame.maxY)].map {
                    scene.convertPoint(toView: scene.convert($0, from: parent))
                }
                guard let minX = corners.map(\.x).min(), let maxX = corners.map(\.x).max(),
                      let minY = corners.map(\.y).min(), let maxY = corners.map(\.y).max() else { return .zero }
                let visibleFrame = CGRect(x: minX, y: minY, width: maxX - minX,
                                          height: maxY - minY).intersection(view.bounds)
                guard visibleFrame.isFinite, !visibleFrame.isEmpty, !visibleFrame.isNull else { return .zero }
                return UIAccessibility.convertToScreenCoordinates(visibleFrame, in: view)
            }
            set { }
        }

        private func isVisible(_ node: SKNode, in scene: SKScene) -> Bool {
            var ancestor: SKNode? = node
            while let current = ancestor {
                guard !current.isHidden, current.alpha > 0.01 else { return false }
                if current === scene { return true }
                ancestor = current.parent
            }
            return false
        }

        private var canActivate: Bool {
            guard let view, let scene, view.scene === scene, !scene.isPaused,
                  view.window?.rootViewController?.presentedViewController == nil,
                  !accessibilityFrame.isEmpty else { return false }
            return item.isEnabled?() ?? true
        }

        override func accessibilityActivate() -> Bool {
            guard canActivate else { return false }
            return item.activate?() ?? false
        }

        override func accessibilityIncrement() {
            guard canActivate else { return }
            item.increment?()
        }

        override func accessibilityDecrement() {
            guard canActivate else { return }
            item.decrement?()
        }
    }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}
