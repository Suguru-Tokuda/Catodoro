//
//  CatodoroAlarmMetadata.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/3/26.
//

import AlarmKit
import Foundation

@available(iOS 26.0, *)
public struct CatodoroAlarmMetadata: AlarmMetadata {
    public let session: Int

    public init(session: Int) {
        self.session = session
    }
}
