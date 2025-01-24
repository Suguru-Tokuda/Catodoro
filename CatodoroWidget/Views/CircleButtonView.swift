//
//  CircleButtonView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/12/25.
//

import SwiftUI

struct CircleButtonView: View {
    let imageSystemName: String
    var onTap: () -> Void = {} // Default empty closure
    var foregroundColor: Color = .white
    var backgroundColor: Color = .gray
    var shadowColor: Color = .gray.opacity(0.5)
    var size: CGFloat = 60
    var padding: CGFloat = 20
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: imageSystemName)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
        }
        .background(backgroundColor)
        .clipShape(Circle())
        .shadow(color: shadowColor, radius: 5, x: 0, y: 3)
        .accessibilityLabel(Text(imageSystemName)) // Accessibility support
    }}

#Preview {
    CircleButtonView(imageSystemName: "play", backgroundColor: .green)
    CircleButtonView(imageSystemName: "pause", backgroundColor: .orange)
    CircleButtonView(imageSystemName: "multiply", backgroundColor: .red)
}
