//
//  MoreAppsViewController.swift
//  Financial Statements Go
//
//  Created by Banghua Zhao on 1/1/21.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif

class MoreAppsViewController: UIViewController {
    var isAds: Bool = false

    #if !targetEnvironment(macCatalyst)
        private var privacyObserver: NSObjectProtocol?
        private let adContainer = UIView()
        private var bannerView: BannerView?
        private lazy var bannerHeightConstraint = adContainer.heightAnchor.constraint(equalToConstant: 0)
        private lazy var tableBottomGapConstraint = tableView.bottomAnchor.constraint(equalTo: adContainer.topAnchor)

        let appItems = [
            AppItem(
                title: "Relaxing Up".localized(),
                detail: "Meditation,Healing".localized(),
                icon: UIImage(named: "relaxing_up"),
                url: URL(string: "https://apps.apple.com/app/id1618712178")),
           AppItem(
                title: "Solitaire Guru".localized(),
                detail: "klondike & solitaire".localized(),
                icon: UIImage(named: "solitaire_guru"),
                url: URL(string: "https://apps.apple.com/app/id1636116344")),
            AppItem(
                title: "Saving Ambulance!Sliding Block".localized(),
                detail: "Sliding Puzzle With Cars".localized(),
                icon: UIImage(named: "saving_ambulance"),
                url: URL(string: "https://apps.apple.com/app/id1639693525")),
            AppItem(
                title: "Sudoku Lover".localized(),
                detail: "Sudoku Lover".localized(),
                icon: UIImage(named: "sudoku_lover"),
                url: URL(string: "https://apps.apple.com/app/id1620749798")),
            AppItem(
                title: "Yes Habit".localized(),
                detail: "Habit Tracker".localized(),
                icon: UIImage(named: "yes_habit"),
                url: URL(string: "https://apps.apple.com/app/id1637643734")),
            AppItem(
                title: "Falling Block Puzzle".localized(),
                detail: "Arcade Game&Brick Game".localized(),
                icon: UIImage(named: "falling_block_puzzle"),
                url: URL(string: "https://apps.apple.com/app/id1609440799")),
            AppItem(
                title: "Fling Knife".localized(),
                detail: "Knife games".localized(),
                icon: UIImage(named: "fling_knife"),
                url: URL(string: "https://apps.apple.com/app/id1636426217")),
            AppItem(
                title: "Instant Face".localized(),
                detail: "Avatar Maker".localized(),
                icon: UIImage(named: "instant_face"),
                url: URL(string: "https://apps.apple.com/app/id1638563222")),
            AppItem(
                title: "Minesweeper Z".localized(),
                detail: "Minesweeper App".localized(),
                icon: UIImage(named: "minesweeper_go"),
                url: URL(string: "https://apps.apple.com/app/id1621899572")),
            AppItem(
                title: "We Play Piano".localized(),
                detail: "Piano Keyboard".localized(),
                icon: UIImage(named: "we_play_piano"),
                url: URL(string: "https://apps.apple.com/app/id1625018611")),
            AppItem(
                title: "Memory Games".localized(),
                detail: "Match Pairs Card".localized(),
                icon: UIImage(named: "classic_memory_game"),
                url: URL(string: "https://apps.apple.com/app/id1617593078")),
            AppItem(
                title: "Image Guru".localized(),
                detail: "Photo Editor,Filter".localized(),
                icon: UIImage(named: "image_guru"),
                url: URL(string: "https://apps.apple.com/app/id1625021625")),
            AppItem(
                title: "Metronome Go".localized(),
                detail: "tempo,bpm-counter".localized(),
                icon: UIImage(named: "metronome_go"),
                url: URL(string: "https://apps.apple.com/app/id1635462172")),
            AppItem(
                title: "Finance Go".localized(),
                detail: "Financial Reports & Investing".localized(),
                icon: UIImage(named: "appIcon_financeGo"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.financeGoAppID)")),
            AppItem(
                title: "Financial Ratios Go".localized(),
                detail: "Finance, Ratios, Investing".localized(),
                icon: UIImage(named: "appIcon_financialRatiosGo"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.financialRatiosGoAppID)")),
            AppItem(
                title: "Money Tracker".localized(),
                detail: "Budget, Expense & Bill Planner".localized(),
                icon: UIImage(named: "appIcon_moneyTracker"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.moneyTrackerAppID)")),
            AppItem(
                title: "BMI Diary".localized(),
                detail: "Fitness, Weight Loss &Health".localized(),
                icon: UIImage(named: "appIcon_bmiDiary"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.BMIDiaryAppID)")),
            AppItem(
                title: "Novels Hub".localized(),
                detail: "Fiction eBooks Library!".localized(),
                icon: UIImage(named: "appIcon_novels_Hub"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.novelsHubAppID)")),
            AppItem(
                title: "More Apps".localized(),
                detail: "Check out more Apps made by us".localized(),
                icon: UIImage(named: "appIcon_appStore"),
                url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
        ]
    #else
        let appItems = [
            AppItem(
                title: "Finance Go".localized(),
                detail: "Financial Reports & Investing".localized(),
                icon: UIImage(named: "appIcon_financeGo"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.financeGoAppID)")),
            AppItem(
                title: "Ratios Go".localized(),
                detail: "Finance, Ratios, Investing".localized(),
                icon: UIImage(named: "appIcon_financialRatiosGo"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.finanicalRatiosGoMacOSAppID)")),
            AppItem(
                title: "Money Tracker".localized(),
                detail: "Budget, Expense & Bill Planner".localized(),
                icon: UIImage(named: "appIcon_moneyTracker"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.moneyTrackerAppID)")),
            AppItem(
                title: "BMI Diary".localized(),
                detail: "Fitness, Weight Loss &Health".localized(),
                icon: UIImage(named: "appIcon_bmiDiary"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.BMIDiaryAppID)")),
            AppItem(
                title: "Novels Hub".localized(),
                detail: "Fiction eBooks Library!".localized(),
                icon: UIImage(named: "appIcon_novels_Hub"),
                url: URL(string: "https://apps.apple.com/app/id\(Constants.novelsHubAppID)")),
            AppItem(
                title: "More Apps".localized(),
                detail: "Check out more Apps made by us".localized(),
                icon: UIImage(named: "appIcon_appStore"),
                url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
        ]
    #endif

    lazy var backButton = UIButton(type: .custom).then { button in
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = "Back".localized()
        button.addTarget(self, action: #selector(backToHome), for: .touchUpInside)
    }

    lazy var titleLabel = UILabel().then { label in
        label.font = UIFont.bigTitle
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        if isAds {
            label.text = "More Apps (Ads)".localized()
        } else {
            label.text = "More Apps".localized()
        }
    }

    lazy var tableView = UITableView().then { tv in
        tv.backgroundColor = .clear
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 82
        tv.delegate = self
        tv.dataSource = self
        tv.register(AppItemCell.self, forCellReuseIdentifier: "AppItemCell")
        tv.register(MoreAppsHeaderCell.self, forCellReuseIdentifier: "MoreAppsHeaderCell")

        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tv.tableFooterView = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        #if !targetEnvironment(macCatalyst)
            view.addSubview(adContainer)
            adContainer.translatesAutoresizingMaskIntoConstraints = false
            privacyObserver = NotificationCenter.default.addObserver(
                forName: .adPrivacyDidChange, object: nil, queue: .main
            ) { [weak self] _ in self?.refreshBanner() }
        #endif

        [backButton, titleLabel, tableView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        var constraints = [
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ]
        #if !targetEnvironment(macCatalyst)
            constraints += [
                adContainer.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                adContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                adContainer.widthAnchor.constraint(equalToConstant: 320),
                bannerHeightConstraint,
                tableBottomGapConstraint
            ]
        #else
            constraints.append(tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        #endif
        NSLayoutConstraint.activate(constraints)

        #if !targetEnvironment(macCatalyst)
        refreshBanner()
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    deinit {
        if let privacyObserver { NotificationCenter.default.removeObserver(privacyObserver) }
    }

    private func refreshBanner() {
        bannerView?.removeFromSuperview()
        bannerView = nil
        guard let request = AdPrivacyManager.shared.adRequest() else {
            bannerHeightConstraint.constant = 0
            tableBottomGapConstraint.constant = 0
            return
        }
        bannerHeightConstraint.constant = 50
        tableBottomGapConstraint.constant = -8
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = Constants.bannerAdUnitID
        banner.rootViewController = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        adContainer.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: adContainer.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: adContainer.centerYAnchor)
        ])
        bannerView = banner
        banner.load(request)
    }
    #endif
}

extension MoreAppsViewController {
    @objc func backToHome() {
        dismiss(animated: true, completion: nil)
    }
}

extension MoreAppsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : appItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "MoreAppsHeaderCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppItemCell", for: indexPath)
            (cell as? AppItemCell)?.appItem = appItems[indexPath.row]
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let appItem = appItems[indexPath.row]
            if let url = appItem.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
