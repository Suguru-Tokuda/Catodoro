//
//  CatodoroWidgetBundle.swift
//  CatodoroWidget
//
//  Created by Suguru Tokuda on 1/21/25.
//

import WidgetKit
import SwiftUI

@main
struct CatodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        CatodoroWidget()
        CatodoroWidgetLiveActivity()
    }
}
