//
//  AudioManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/22/24.
//

import AVFoundation

enum AudioError: Error {
    case fileNotFound
    case playerNotSet
    case setup
    case playbackFailed
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
    /// Session and player commands share a serial queue so stop cannot overtake activation.
    static let playbackQueue = DispatchQueue(label: "com.catodoro.audio", qos: .userInitiated)
    private let stateLock = NSLock()
    private var storedState: AudioState = .stopped

    private var _audioState: AudioState {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }

            return storedState
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            storedState = newValue
        }
    }

    var audioState: AudioState {
        _audioState
    }
    private var audioPlayer: AVAudioPlayer?

    func setPlayer(fileName: String, fileExtension: String) throws {
        try audioPlayer = getAudioPlayer(fileName: fileName, fileExtension: fileExtension)
        audioPlayer?.numberOfLoops = 0
    }

    func play(numberOfLoops: Int = 0) throws {
        if let audioPlayer {
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            audioPlayer.numberOfLoops = numberOfLoops
            // Activate at playback time; another app may have taken the session since setup.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)

            guard audioPlayer.play() else {
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
                throw AudioError.playbackFailed
            }

            _audioState = .playing
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func pause() throws {
        if let audioPlayer {
            audioPlayer.pause()
            _audioState = .paused
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func stop() throws {
        _audioState = .stopped

        if let audioPlayer {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
        Self.playbackQueue.async { [weak self] in
            guard let self else {
                return
            }

            // Ignore a delayed completion callback if a new cue is already playing.
            guard !audioPlayer.isPlaying else {
                return
            }

            _audioState = .stopped
            audioPlayer.currentTime = 0
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
