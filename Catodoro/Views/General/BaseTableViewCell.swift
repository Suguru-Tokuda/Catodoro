//
//  BaseTableViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/1/25.
//

import UIKit

class BaseTableViewCell: UITableViewCell, Constructable {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        constructView()
        constructSubviews()
        constructSubviewLayoutConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        constructView()
        constructSubviews()
        constructSubviewLayoutConstraints()
    }

    func constructView() {
        backgroundColor = CatTheme.card
    }

    func constructSubviews() {}

    func constructSubviewLayoutConstraints() {}
}
