//
//  StopButton.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/19/24.
//

import UIKit

class StopButton: UIButton {
    var onButtonTap: (() -> ())?
    let buttonHeight = 80
    let buttonWidth = 80

    init() {
        super.init(frame: .zero)
        let config = UIImage.SymbolConfiguration(weight: .thin)
        self.setImage(UIImage(systemName: "stop.fill", withConfiguration: config)?
                        .resizedTo(.init(width: buttonWidth, height: buttonHeight))
                        .withTintColor(.white),
                                  for: .normal)
        self.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension StopButton {
    @objc private func handleButtonTap() {
        onButtonTap?()
    }
}
