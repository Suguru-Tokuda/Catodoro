//
//  PresetImagePickerViewViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/30/26.
//

import CatodoroShared
import UIKit

final class PresetImagePickerViewController: BaseViewController {
    var onSelect: ((CatPose) -> Void)?
    
    private let pickerView = PresetImagePickerView()

    override func loadView() {
        view = pickerView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = ColorOptions.neonBlue.color
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppStrings.Common.chooseYourCat

        pickerView.onSelect = { [weak self] pose in
            self?.onSelect?(pose)
        }
    }
}
