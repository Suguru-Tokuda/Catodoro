//
//  PawButton.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/23/24.
//

import UIKit

class PawButton: UIButton {
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private var pawImage: UIImageView = {
       let imageView = UIImageView(image: UIImage(systemName: "pawprint.fill"))
        return imageView
    }()

    private var label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        label.text = title
        stackView.addArrangedSubviews([label, pawImage])
        addAutolayoutSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            pawImage.heightAnchor.constraint(equalToConstant: 48),
            pawImage.widthAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    func setColor(_ color: UIColor, for state: UIControl.State) {
        pawImage.tintColor = color
    }
}

#if DEBUG
extension PawButton {
    var testHooks: TestHooks {
        .init(target: self)
    }
    
    struct TestHooks {
        let target: PawButton

        var label: UILabel { target.label }
        var pawImage: UIImageView { target.pawImage }
        var stackView: UIStackView { target.stackView }
    }
}
#endif
