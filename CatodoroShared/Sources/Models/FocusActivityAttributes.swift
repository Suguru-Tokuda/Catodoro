//
//  FocusActivityAttributes.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/7/26.
//

import ActivityKit
import Foundation

nonisolated public struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endDate: Date
        public var pauseRemaining: TimeInterval?

        public init(endDate: Date, pauseRemaining: TimeInterval? = nil) {
            self.endDate = endDate
            self.pauseRemaining = pauseRemaining
        }
    }

    public var sessionID: String
    public var label: String

    public init(sessionID: String, label: String) {
        self.sessionID = sessionID
        self.label = label
    }
}
