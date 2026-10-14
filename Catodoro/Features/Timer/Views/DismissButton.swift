//
//  DismissButton.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/29/24.
//

import UIKit

class DismissButton: UIButton {
    var onButtonTap: (() -> ())?
    let buttonHeight = 80
    let buttonWidth = 80

    init() {
        super.init(frame: .zero)
        let config = UIImage.SymbolConfiguration(weight: .thin)
        self.setImage(UIImage(systemName: "multiply.circle", withConfiguration: config)?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
                        .resizedTo(.init(width: buttonWidth, height: buttonHeight))
                        .withTintColor(.white),
                                  for: .normal)
        self.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        nil
    }
}

extension DismissButton {
    @objc private func handleButtonTap() {
        onButtonTap?()
    }
}
