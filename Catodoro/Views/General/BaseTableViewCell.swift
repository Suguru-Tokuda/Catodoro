//
//  BaseTableViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/1/25.
//

import UIKit

class BaseTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupSubviews()
        setupConstraints()
    }

    func setupView() {}
    func setupSubviews() {}
    func setupConstraints() {}
}
