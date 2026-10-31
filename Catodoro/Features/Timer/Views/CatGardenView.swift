//
//  CatGardenView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/31/26.
//

import UIKit

final class CatGardenView: BaseView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ rect: CGRect) {
        CatTheme.color(0xF1E4CF, 0x39313A).setFill()
        UIBezierPath(ovalIn: CGRect(x: 8, y: rect.height - 22, width: rect.width - 16, height: 20)).fill()

        let plantX = rect.width * 0.84
        CatTheme.color(0x8A9F7C, 0x71856D).setStroke()
        let stem = UIBezierPath()
        stem.move(to: CGPoint(x: plantX, y: rect.height - 32))
        stem.addQuadCurve(to: CGPoint(x: plantX - 8, y: 38), controlPoint: CGPoint(x: plantX - 16, y: 100))
        stem.lineWidth = 3
        stem.stroke()

        for index in 0..<5 {
            let left = index % 2 == 0
            let leaf = UIBezierPath()
            let y = CGFloat(45 + index * 22)
            let x = plantX - 8
            leaf.move(to: CGPoint(x: x, y: y + 25))
            leaf.addQuadCurve(to: CGPoint(x: x + (left ? -35 : 35), y: y - 8),
                              controlPoint: CGPoint(x: x + (left ? -48 : 48), y: y + 20))
            leaf.addQuadCurve(to: CGPoint(x: x, y: y + 25),
                              controlPoint: CGPoint(x: x + (left ? -5 : 5), y: y - 20))
            CatTheme.color(index % 2 == 0 ? 0x9BAF8C : 0x7E9973, 0x63795E).setFill()
            leaf.fill()
        }

        CatTheme.color(0xE3D4BC, 0x776858).setFill()
        let pot = UIBezierPath(roundedRect: CGRect(x: plantX - 25, y: rect.height - 48, width: 50, height: 38), cornerRadius: 12)
        pot.fill()
    }
}
