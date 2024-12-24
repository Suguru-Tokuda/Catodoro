//
//  AudioManagerMock.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import Foundation
@testable import Catodoro

final class AudioManagerMock: AudioManaging {
    var playedFileName: String?
    var playedFileExtension: String?
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var isStopped: Bool = false

    func setPlayer(fileName: String, fileExtension: String) throws {
        playedFileName = fileName
        playedFileExtension = fileExtension
    }

    func play() throws {
        isPlaying = true
        isPaused = false
    }

    func pause() throws {
        isPlaying = false
        isPaused = true
    }

    func stop() throws {
        isPlaying = false
        isPaused = false
        isStopped = true
    }
}
