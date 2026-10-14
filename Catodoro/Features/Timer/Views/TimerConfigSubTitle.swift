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
        font = CatTheme.font(.title2, weight: .bold)
        textColor = CatTheme.text
        adjustsFontForContentSizeCategory = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = CatTheme.font(.title2, weight: .bold)
        textColor = CatTheme.text
        adjustsFontForContentSizeCategory = true
    }
    
    required init?(coder: NSCoder) {
         nil
    }    
}
