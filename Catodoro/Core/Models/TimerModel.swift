//
//  TimerModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

struct TimerModel {
    let hours: Int
    let minutes: Int
    let seconds: Int

    var duration: TimeInterval {
        let hoursInSeconds: TimeInterval = Double(hours) * 3600
        let minutesInSeconds: TimeInterval = Double(minutes) * 60
        let secondsInSeconds: TimeInterval = Double(seconds)
            
        return hoursInSeconds + minutesInSeconds + secondsInSeconds
    }
}
