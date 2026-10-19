import UIKit

/// A read-only view of progress and winning records. The presenting controller
/// owns dismissal and revalidates a selected level before opening it.
final class LevelRecordsViewController: UITableViewController {
    var onSelectLevel: ((Int) -> Void)?
    var onClose: (() -> Void)?

    private let progress: LevelProgress
    private var isHandlingSelection = false

    init(progress: LevelProgress) {
        self.progress = progress
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Level Records".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized(), style: .done, target: self, action: #selector(close))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        progress.totalLevels
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard (1...progress.totalLevels).contains(where: { LevelChallenge.targetRemovals(for: $0) != nil })
        else { return nil }
        return "Optional challenge: win within the removal target to earn a medal.".localized()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "LevelRecord"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let level = indexPath.row + 1
        let isUnlocked = level <= progress.unlockedLevel
        let isCompleted = level <= progress.completedLevels
        let medalEarned = LevelChallenge.medalEarned(for: level)
        let levelTitle = String(format: "Level %d".localized(), level)
        let status = (isCompleted ? "Completed" : isUnlocked ? "Available" : "Locked").localized()
        let best = LevelRecordStore.bestRemovals(for: level)
            .map { String(format: "Best: %d".localized(), $0) } ?? "No record yet".localized()
        var details = [status, best]
        if let target = LevelChallenge.targetRemovals(for: level) {
            details.append(String(format: "Target: %d".localized(), target))
            if medalEarned { details.append("Challenge complete".localized()) }
        }

        cell.textLabel?.text = levelTitle
        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = isUnlocked ? .label : .secondaryLabel
        cell.detailTextLabel?.text = details.joined(separator: "\n")
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        let symbol = !isUnlocked ? "lock.fill"
            : medalEarned ? "star.circle.fill" : isCompleted ? "checkmark.circle.fill" : "play.circle"
        cell.imageView?.image = UIImage(systemName: symbol)
        cell.imageView?.tintColor = !isUnlocked ? .secondaryLabel : medalEarned ? .systemOrange : .systemGreen
        cell.accessoryType = isUnlocked ? .disclosureIndicator : .none
        cell.selectionStyle = isUnlocked ? .default : .none
        cell.isAccessibilityElement = true
        var spokenDetails = [status, LevelRecordStore.bestRemovals(for: level)
            .map { String(format: "Best: %d removals".localized(), $0) } ?? "No record yet".localized()]
        if let target = LevelChallenge.targetRemovals(for: level) {
            spokenDetails.append(String(format: "Target: %d removals".localized(), target))
            if medalEarned { spokenDetails.append("Challenge complete".localized()) }
        }
        cell.accessibilityLabel = ([levelTitle] + spokenDetails).joined(separator: ", ")
        cell.accessibilityHint = (isUnlocked ? "Double-tap to play" : "Finish earlier levels to unlock").localized()
        cell.accessibilityTraits = isUnlocked ? [.button] : [.staticText, .notEnabled]
        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard !isHandlingSelection, indexPath.row + 1 <= progress.unlockedLevel else { return nil }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let level = indexPath.row + 1
        guard !isHandlingSelection, (1...progress.unlockedLevel).contains(level),
              let onSelectLevel else { return }
        isHandlingSelection = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        onSelectLevel(level)
    }

    @objc private func close() {
        guard !isHandlingSelection, let onClose else { return }
        isHandlingSelection = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        onClose()
    }
}
