//
//  CatCardView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit

class CatCardView: BaseView {
    private func updateBorder() {
        layer.borderColor = CatTheme.separator.resolvedColor(with: traitCollection).cgColor
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateBorder()
    }

    override func constructView() {
        super.constructView()

        backgroundColor = CatTheme.card
        layer.cornerRadius = CatTheme.cardRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: CatCardView, _: UITraitCollection) in
            view.updateBorder()
        }

        updateBorder()
    }
}
