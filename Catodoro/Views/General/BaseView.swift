//
//  BaseView.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 1/1/25.
//

import UIKit

class BaseView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {}
    func setupSubviews() {}
    func setupConstraints() {}
}
