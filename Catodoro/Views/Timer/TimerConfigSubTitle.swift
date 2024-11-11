//
//  TimerConfigSubTitle.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerConfigSubTitle: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: 26, weight: .bold)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 26, weight: .bold)
    }
    
    required init?(coder: NSCoder) {
         nil
    }    
}
