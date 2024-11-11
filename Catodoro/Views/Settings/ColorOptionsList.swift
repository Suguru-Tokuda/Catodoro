//
//  ColorOptionsList.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class ColorOptionsList: UITableView {
    init() {
        super.init(frame: .zero, style: .plain)
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    private func setUpUI() {
        register(ColorPickOptionViewCell.self, forCellReuseIdentifier: ColorPickOptionViewCell.reuseIdentifier)
    }
}
