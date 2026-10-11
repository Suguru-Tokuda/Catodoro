//
//  AudioManagerMock.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import Foundation
@testable import Catodoro

final class MockAudioManager: AudioManaging {
    var audioState: Catodoro.AudioState = .stopped
    
    var playedFileName: String?
    var playedFileExtension: String?
    private(set) var wasCalledOnMainThread = false
    private(set) var commands: [String] = []
    private(set) var playCount = 0
    private(set) var lastNumberOfLoops: Int?
    var playbackError: Error?
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var isStopped: Bool = false

    func setPlayer(fileName: String, fileExtension: String) throws {
        wasCalledOnMainThread = wasCalledOnMainThread || Thread.isMainThread
        commands.append("setup")
        playedFileName = fileName
        playedFileExtension = fileExtension
    }

    func play(numberOfLoops: Int) throws {
        wasCalledOnMainThread = wasCalledOnMainThread || Thread.isMainThread
        commands.append("play")
        if let playbackError {
            throw playbackError
        }

        playCount += 1
        lastNumberOfLoops = numberOfLoops
        isPlaying = true
        isPaused = false
    }

    func pause() throws {
        isPlaying = false
        isPaused = true
    }

    func stop() throws {
        wasCalledOnMainThread = wasCalledOnMainThread || Thread.isMainThread
        commands.append("stop")
        isPlaying = false
        isPaused = false
        isStopped = true
    }
}
