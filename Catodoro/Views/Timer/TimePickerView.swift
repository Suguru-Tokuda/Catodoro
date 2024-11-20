//
//  TimePickerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/7/24.
//

import UIKit

class TimePickerView: UIPickerView {
    var onSelect: ((Int) -> Void)?
    var timeOptions: [Int]

    init(frame: CGRect, min: Int = 0, max: Int) {
        timeOptions = []
        for i in min...max { timeOptions.append(i) }
        super.init(frame: frame)
        dataSource = self
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        nil
    }
}

extension TimePickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        timeOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        String(timeOptions[row])
    }
}

extension TimePickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSelect?(timeOptions[row])
    }
}
