//
//  AudioManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/22/24.
//

import AVFoundation

enum AudioError: Error {
    case fileNotFound,
         playerNotSet,
         setup
}

enum AudioState {
    case playing
    case paused
    case stopped
}

protocol AudioManaging {
    var audioState: AudioState { get }
    func setPlayer(fileName: String, fileExtension: String) throws
    func play(numberOfLoops: Int) throws
    func pause() throws
    func stop() throws
}

class AudioManager: NSObject, AudioManaging {
    private var _audioStatte: AudioState = .stopped
    var audioState: AudioState {
        _audioStatte
    }
    private var audioPlayer: AVAudioPlayer?
    var playTimer: Timer?
    let loopDelay = 1.0

    func setPlayer(fileName: String, fileExtension: String) throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw AudioError.setup
        }
        try audioPlayer = getAudioPlayer(fileName: fileName, fileExtension: fileExtension)
        audioPlayer?.numberOfLoops = 0
    }

    func play(numberOfLoops: Int = 0) throws {
        if let audioPlayer {
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            audioPlayer.numberOfLoops = numberOfLoops
            playTimer?.invalidate()
            playTimer = nil
            audioPlayer.play()
            _audioStatte = .playing
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func pause() throws {
        if let audioPlayer {
            audioPlayer.pause()
            _audioStatte = .paused
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func stop() throws {
        playTimer?.invalidate()
        playTimer = nil
        _audioStatte = .stopped
        if let audioPlayer {
            audioPlayer.stop()
        } else {
            throw AudioError.playerNotSet
        }
    }

    private func getAudioPlayer(fileName: String, fileExtension: String) throws -> AVAudioPlayer {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            throw AudioError.fileNotFound
        }
        return try AVAudioPlayer(contentsOf: url)
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ audioPlayer: AVAudioPlayer, successfully flag: Bool) {
        playTimer = Timer.scheduledTimer(withTimeInterval: loopDelay, repeats: false) { [weak self] _ in
            guard self != nil else { return }
            audioPlayer.currentTime = 0
            audioPlayer.play()
        }
    }
}
