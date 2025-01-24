//
//  CatodoroSharedPreferences.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/12/25.
//

import CatodoroShared
import Foundation

public struct TimerStateModel {
    var totalDuration: TimeInterval
    var intervalDuration: TimeInterval
    var intervals: Int
    var interval: Int // Indicates the current interval position
    var timerType: TimerType
    var timerStatus: TimerStatus
}

public protocol CatodoroSharedPreferencesProtocol {
    func saveTimerState(state: TimerStateModel)
    func getTimerState() -> TimerStateModel?
}

public enum SharedPreferencesKeys: String {
    case totalDuration
    case intervalDuration
    case intervals
    case interval
    case timerType
    case timerStatus
}

public class CatodoroSharedPreferences: CatodoroSharedPreferencesProtocol {
    private let suiteName = "group.com.sugurutokuda.catodoro"
    private var sharedDefaults: UserDefaults?

    init(sharedDefaults: UserDefaults?) {
        self.sharedDefaults = sharedDefaults

        if self.sharedDefaults == nil {
            self.sharedDefaults = UserDefaults(suiteName: suiteName)
        }
    }

    public func saveTimerState(state: TimerStateModel) {
        guard let sharedDefaults else { return }

        sharedDefaults.setValue(state.totalDuration, forKey: SharedPreferencesKeys.totalDuration.rawValue)
        sharedDefaults.setValue(state.intervalDuration, forKey: SharedPreferencesKeys.intervalDuration.rawValue)
        sharedDefaults.setValue(state.intervals, forKey: SharedPreferencesKeys.intervals.rawValue)
        sharedDefaults.setValue(state.interval, forKey: SharedPreferencesKeys.interval.rawValue)
        sharedDefaults.setValue(state.timerType.rawValue, forKey: SharedPreferencesKeys.timerType.rawValue)
        sharedDefaults.setValue(state.timerStatus.rawValue, forKey: SharedPreferencesKeys.timerStatus.rawValue)
    }
    
    public func getTimerState() -> TimerStateModel? {
        guard let sharedDefaults else { return nil }
        return TimerStateModel(totalDuration: sharedDefaults.value(forKey: SharedPreferencesKeys.totalDuration.rawValue) as? TimeInterval ?? 0,
                               intervalDuration: sharedDefaults.value(forKey: SharedPreferencesKeys.intervalDuration.rawValue) as? TimeInterval ?? 0,
                               intervals: sharedDefaults.value(forKey: SharedPreferencesKeys.intervals.rawValue) as? Int ?? 0,
                               interval: sharedDefaults.value(forKey: SharedPreferencesKeys.interval.rawValue) as? Int ?? 0,
                               timerType: TimerType(rawValue: sharedDefaults.value(forKey: SharedPreferencesKeys.timerType.rawValue) as? String ?? "") ?? .main,
                               timerStatus: TimerStatus(rawValue: sharedDefaults.value(forKey: SharedPreferencesKeys.timerStatus.rawValue) as? String ?? "") ?? .paused)
    }
}
