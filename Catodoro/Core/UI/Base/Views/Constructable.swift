//
//  Constructable.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import Foundation

protocol Constructable {
    func constructView()
    func constructSubviews()
    func constructSubviewLayoutConstraints()
}
