//
//  AppItemCell.swift
//  Financial Statements Go
//
//  Created by Banghua Zhao on 1/1/21.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import UIKit

class AppItemCell: UITableViewCell {
    var appItem: AppItem? {
        didSet {
            guard let appItem = appItem else { return }
            iconView.image = appItem.icon
            titleLabel.text = appItem.title
            detailLabel.text = appItem.detail
        }
    }

    lazy var iconView = UIImageView().then { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 9
        imageView.layer.masksToBounds = true
    }

    lazy var titleLabel = UILabel().then { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .label
        label.font = UIFont.title
    }

    lazy var detailLabel = UILabel().then { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .secondaryLabel
        label.font = UIFont.normal
    }

    lazy var rightArrowImageView = UIImageView().then { imageView in
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "chevron.right")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(iconView)
        contentView.addSubview(rightArrowImageView)

        [iconView, titleLabel, detailLabel, rightArrowImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textStack)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: rightArrowImageView.leadingAnchor, constant: -12),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightArrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rightArrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightArrowImageView.widthAnchor.constraint(equalToConstant: 12),
            rightArrowImageView.heightAnchor.constraint(equalToConstant: 16),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
