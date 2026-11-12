//
//  SoundSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation

/// Lists the alert sounds, saves the one the user picks and plays a preview of it.
final class SoundSelectionViewModel {
    private(set) var options: [OptionModel]
    /// Called on the main queue when a preview can't be played.
    var onPreviewFailed: ((Error) -> Void)?

    private let preferences: CatodoroPreferencesProtocol?
    private let audioManager: AudioManaging

    init(preferences: CatodoroPreferencesProtocol?, audioManager: AudioManaging = AudioManager()) {
        self.preferences = preferences
        self.audioManager = audioManager
        let selectedID = SoundOptions(preferences?.sound ?? "").id
        options = SoundOptions.allCases.map {
            OptionModel(id: $0.id, title: $0.title, selected: $0.id == selectedID)
        }
    }

    var selectedSound: SoundOptions? {
        options.first(where: \.selected).map { SoundOptions($0.id) }
    }

    func selectOption(at index: Int) {
        guard options.indices.contains(index) else { return }
        let sound = SoundOptions(options[index].id)
        preferences?.setSound(sound)
        options = options.selecting(id: sound.id)
        preview(sound)
    }

    func stopPreview() {
        let manager = audioManager
        AudioManager.playbackQueue.async {
            try? manager.stop()
        }
    }

    private func preview(_ sound: SoundOptions) {
        let manager = audioManager
        let fileName = sound.fileName
        AudioManager.playbackQueue.async { [weak self] in
            do {
                try manager.stop()
                try manager.setPlayer(fileName: fileName, fileExtension: "mp3")
                try manager.play(numberOfLoops: 0)
            } catch {
                DispatchQueue.main.async {
                    self?.onPreviewFailed?(error)
                }
            }
        }
    }
}
