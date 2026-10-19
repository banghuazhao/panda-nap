import UIKit

/// A read-only view of progress and winning records. The presenting controller
/// owns dismissal and revalidates a selected level before opening it.
final class LevelRecordsViewController: UITableViewController {
    var onSelectLevel: ((Int) -> Void)?
    var onClose: (() -> Void)?

    private let progress: LevelProgress
    private let defaults: UserDefaults
    private var isHandlingSelection = false
    private var filterButton: UIBarButtonItem?
    private var surpriseButton: UIBarButtonItem?
    private(set) var filter: RecordsFilter = .all
    private(set) var visibleLevels: [Int]

    init(progress: LevelProgress, defaults: UserDefaults = .standard) {
        self.progress = progress
        self.defaults = defaults
        visibleLevels = ReplayOptions.visibleLevels(filter: .all, progress: progress, defaults: defaults)
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Level Records".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized(), style: .done, target: self, action: #selector(close))
        let filterControl = UIBarButtonItem(title: "Filter".localized(), style: .plain,
                                            target: self, action: #selector(showFilters))
        filterControl.accessibilityValue = filter.rawValue.localized()
        navigationItem.leftBarButtonItem = filterControl
        filterButton = filterControl
        if !ReplayOptions.completedLevels(progress: progress).isEmpty {
            let surprise = UIBarButtonItem(title: "Surprise Replay".localized(), style: .plain,
                                           target: self, action: #selector(replaySurprise))
            surprise.accessibilityHint = "Replay a random completed level".localized()
            surpriseButton = surprise
            toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                            surprise,
                            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(surpriseButton == nil, animated: false)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Keep the empty message in a self-sizing, scrollable row so it remains
        // readable at accessibility text sizes in a short landscape sheet.
        max(1, visibleLevels.count)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        filter.rawValue.localized()
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard visibleLevels.contains(where: { LevelChallenge.targetRemovals(for: $0) != nil })
        else { return nil }
        return "Optional challenge: win within the removal target to earn a medal.".localized()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !visibleLevels.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyRecords")
                ?? UITableViewCell(style: .default, reuseIdentifier: "EmptyRecords")
            cell.textLabel?.text = "No levels match this filter.".localized()
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            cell.isAccessibilityElement = true
            cell.accessibilityTraits = .staticText
            return cell
        }
        let identifier = "LevelRecord"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        guard let level = level(at: indexPath) else { return cell }
        let isUnlocked = level <= progress.unlockedLevel
        let isCompleted = level <= progress.completedLevels
        let medalEarned = LevelChallenge.medalEarned(for: level, defaults: defaults)
        let levelTitle = LevelCatalog.title(for: level)
        let status = (isCompleted ? "Completed" : isUnlocked ? "Available" : "Locked").localized()
        let best = LevelRecordStore.bestRemovals(for: level, defaults: defaults)
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
        var spokenDetails = [status, LevelRecordStore.bestRemovals(for: level, defaults: defaults)
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
        guard !isHandlingSelection, let level = level(at: indexPath),
              level <= progress.unlockedLevel else { return nil }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let level = level(at: indexPath) else { return }
        selectLevel(level)
    }

    func level(at indexPath: IndexPath) -> Int? {
        guard indexPath.section == 0, visibleLevels.indices.contains(indexPath.row) else { return nil }
        return visibleLevels[indexPath.row]
    }

    func applyFilter(_ filter: RecordsFilter) {
        guard !isHandlingSelection else { return }
        self.filter = filter
        visibleLevels = ReplayOptions.visibleLevels(filter: filter, progress: progress, defaults: defaults)
        filterButton?.accessibilityValue = filter.rawValue.localized()
        guard isViewLoaded else { return }
        tableView.reloadData()
        if !visibleLevels.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    @objc func replaySurprise() {
        guard !isHandlingSelection, let level = ReplayOptions.surpriseLevel(progress: progress) else { return }
        selectLevel(level)
    }

    private func selectLevel(_ level: Int) {
        guard !isHandlingSelection, (1...progress.unlockedLevel).contains(level),
              let onSelectLevel else { return }
        isHandlingSelection = true
        disableControls()
        onSelectLevel(level)
    }

    @objc private func showFilters() {
        guard !isHandlingSelection, presentedViewController == nil else { return }
        let sheet = UIAlertController(title: "Filter".localized(), message: nil, preferredStyle: .actionSheet)
        for option in RecordsFilter.allCases {
            sheet.addAction(UIAlertAction(title: option.rawValue.localized(), style: .default) { [weak self] _ in
                self?.applyFilter(option)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = filterButton
        present(sheet, animated: true)
    }

    private func disableControls() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        filterButton?.isEnabled = false
        surpriseButton?.isEnabled = false
    }

    @objc private func close() {
        guard !isHandlingSelection, let onClose else { return }
        isHandlingSelection = true
        disableControls()
        onClose()
    }
}
