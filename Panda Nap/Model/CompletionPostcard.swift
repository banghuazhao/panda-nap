import UIKit

/// A bounded, self-contained export of the earned reward, without game state or personal data.
@MainActor
enum CompletionPostcard {
    static func image() -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor(red: 0.09, green: 0.22, blue: 0.15, alpha: 1).setFill()
            context.fill(bounds)

            let card = UIBezierPath(roundedRect: bounds.insetBy(dx: 32, dy: 32), cornerRadius: 40)
            UIColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 1).setStroke()
            card.lineWidth = 4
            card.stroke()

            draw("Panda Nap".localized(), in: CGRect(x: 80, y: 80, width: 1040, height: 60),
                 size: 38, color: UIColor(red: 0.76, green: 0.91, blue: 0.59, alpha: 1))
            draw("Nap Champion".localized(), in: CGRect(x: 80, y: 155, width: 1040, height: 100),
                 size: 70, weight: .bold)
            if let panda = UIImage(named: "panda_sleep"), panda.size.width > 0, panda.size.height > 0 {
                let available = CGRect(x: 330, y: 285, width: 540, height: 300)
                let scale = min(available.width / panda.size.width, available.height / panda.size.height)
                let scaled = CGSize(width: panda.size.width * scale, height: panda.size.height * scale)
                panda.draw(in: CGRect(x: available.midX - scaled.width / 2,
                                      y: available.midY - scaled.height / 2,
                                      width: scaled.width, height: scaled.height))
            }
            draw("Sweet dreams, Panda!".localized(), in: CGRect(x: 80, y: 620, width: 1040, height: 65),
                 size: 42, weight: .semibold)
            let completion = String(format: "You guided Panda through all %d levels.".localized(), Constants.totalLevel)
            draw(completion, in: CGRect(x: 100, y: 720, width: 1000, height: 100), size: 34)
        }
    }

    private static func draw(_ text: String, in rect: CGRect, size: CGFloat,
                             weight: UIFont.Weight = .medium, color: UIColor = .white) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        (text as NSString).draw(in: rect, withAttributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ])
    }
}
