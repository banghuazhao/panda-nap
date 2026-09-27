//
//  MoreAppsHeaderCell.swift
//  Countdown Days
//
//  Created by Banghua Zhao on 2021/1/24.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import UIKit

class MoreAppsHeaderCell: UITableViewCell {
    lazy var label = UILabel().then { label in
        label.text = "Apps".localized()
        label.font = UIFont.title
        label.numberOfLines = 0
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        tintColor = .clear
        selectionStyle = .none
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
