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
         setUp
}

protocol AudioManaging {
    func setPlayer(fileName: String, fileExtension: String) throws
    func play() throws
    func pause() throws
    func stop() throws
}

class AudioManager: AudioManaging {
    private var audioPlayer: AVAudioPlayer?

    func setPlayer(fileName: String, fileExtension: String) throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw AudioError.setUp
        }
        try audioPlayer = getAudioPlayer(fileName: fileName, fileExtension: fileExtension)
        audioPlayer?.numberOfLoops = -1
    }

    func play() throws {
        if let audioPlayer {
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func pause() throws {
        if let audioPlayer {
            audioPlayer.pause()
        } else {
            throw AudioError.playerNotSet
        }
    }
    
    func stop() throws {
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
