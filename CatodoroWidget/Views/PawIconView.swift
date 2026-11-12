//
//  PawIconView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import SwiftUI

struct PawIconView: View {
    let accent: Color
    let accessibilityLabelTitle: String

    var body: some View {
        Image("ActivityCatPaw", bundle: ActivityTheme.imageBundle)
            .resizable()
            .scaledToFit()
            .frame(width: Spacing.space20, height: Spacing.space20)
            .foregroundStyle(accent)
            .accessibilityLabel(accessibilityLabelTitle)
    }
}

