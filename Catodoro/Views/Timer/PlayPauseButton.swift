//
//  PlayPauseButtonView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/27/24.
//

import UIKit

enum TimerButtonStatus {
    case playing,
         paused

    var image: UIImage {
        switch self {
        case .playing:
            return .init(systemName: "pause")!
        case .paused:
            return .init(systemName: "play.fill")!
        }
    }
}

class PlayPauseButton: UIButton {
    var onButtonTap: (() -> ())?
    let buttonHeight = 80
    let buttonWidth = 80
    let config = UIImage.SymbolConfiguration(weight: .thin)

    init() {
        super.init(frame: .zero)
        self.setImage(UIImage(systemName: "play", withConfiguration: config)?
                        .resizedTo(.init(width: buttonWidth, height: buttonHeight))
                        .withTintColor(.white),
                      for: .normal)
        self.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    func configure(timerStatus: TimerButtonStatus) {
        self.setImage(timerStatus
                        .image
                        .withConfiguration(config)
                        .resizedTo(.init(width: buttonWidth, height: buttonHeight))
                        .withTintColor(.white),
                      for: .normal)
    }
}

extension PlayPauseButton {
    @objc private func handleButtonTap() {
        onButtonTap?()
    }
}
