//
//  MockTimerConfigViewModel.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import Foundation
@testable import Catodoro

class MockTimerConfigViewModel: TimerConfigViewModelProtocol {
    var timerModel: Catodoro.TimerConfigModel = .init()
    var isValidSelection: Bool = false
    var shouldThrowError = false
    var addPresetClosure: (() -> Void)?
    
    func addPreset() async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 0, userInfo: nil)
        } else {
            addPresetClosure?()
        }
    }
}
