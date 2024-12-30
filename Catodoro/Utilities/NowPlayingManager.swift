//
//  NowPlayingManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/28/24.
//

import MediaPlayer

protocol NowPlayingManaging {
    var pauseTimer: (() -> Void)? { get set }
    var resumeTimer: (() -> Void)? { get set }
    var stopTimer: (() -> Void)? { get set }

    var duration: TimeInterval { get set }
    var remainingTime: TimeInterval { get set }
    var isPaused: Bool { get set }

    func configureNowPlayingInfo(with duration: TimeInterval,
                                 elapsedTime: TimeInterval,
                                 remainingTime: TimeInterval,
                                 inInterval: Bool,
                                 currentInterval: Int,
                                 intervals: Int,
                                 isPaused: Bool)
}

class NowPlayingManager: NowPlayingManaging {
    // MARK: Closures
    var pauseTimer: (() -> Void)?
    var resumeTimer: (() -> Void)?
    var stopTimer: (() -> Void)?
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    var duration: TimeInterval = 0
    var remainingTime: TimeInterval = 0
    var isPaused: Bool = false

    init() {
        configureCommandCenter()
    }
    
    func configureNowPlayingInfo(with duration: TimeInterval,
                                 elapsedTime: TimeInterval,
                                 remainingTime: TimeInterval,
                                 inInterval: Bool,
                                 currentInterval: Int,
                                 intervals: Int,
                                 isPaused: Bool) {
        self.duration = duration
        self.remainingTime = remainingTime
        self.isPaused = isPaused

        let formattedTime = remainingTime.getTimerLabelValue()

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: "\(inInterval ? "Break" : "Timer") - \(currentInterval)/\(intervals)",
            MPMediaItemPropertyArtist: formattedTime,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPaused ? 0 : 1
        ]

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func configureCommandCenter() {
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true
        commandCenter.skipForwardCommand.removeTarget(self)
        commandCenter.skipBackwardCommand.removeTarget(self)

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            self.pauseTimer?()
            return .success
        }

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            self.resumeTimer?()
            return .success
        }

        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            self.stopTimer?()
            return .success
        }
    }
}
