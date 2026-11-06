//
//  HapticsManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/5/26.
//

import CoreHaptics

protocol HapticsManaging {
    func start() throws
    func stop()
}

final class HapticsManager: HapticsManaging {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    func start() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let engine = try engine ?? makeEngine()
        try engine.start()

        let pulse = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                .init(parameterID: .hapticIntensity, value: 1),
                .init(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0,
            duration: 0.4
        )

        let pattern = try CHHapticPattern(events: [pulse], parameters: [])
        let player = try engine.makeAdvancedPlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)

        self.engine = engine
        self.player = player
    }
    
    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in
            self?.player = nil
        }
        engine.stoppedHandler = { [weak self] _ in
            self?.player = nil
        }
        return engine
    }
}
