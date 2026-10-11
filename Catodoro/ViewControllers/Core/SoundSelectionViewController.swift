//
//  SoundSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

protocol SoundSelectionViewControllerDelegate: AnyObject {
    func onSoundSelect()
}

class SoundSelectionViewController: BaseOptionSelectionViewController {
    weak var delegate: SoundSelectionViewControllerDelegate?
    private let audioManager: AudioManaging
    var viewModel: OptionSelectionViewModel

    init(viewModel: OptionSelectionViewModel, titleLabelText: String, audioManager: AudioManaging = AudioManager()) {
        self.audioManager = audioManager
        self.viewModel = viewModel
        super.init(titleLabelText: titleLabelText)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        optionTableView.delegate = self
        optionTableView.dataSource = self
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || navigationController?.isBeingDismissed == true else { return }

        let manager = audioManager
        AudioManager.playbackQueue.async {
            try? manager.stop()
        }
    }

    @objc private func doneTapped() {
        delegate?.onSoundSelect()
    }
}

extension SoundSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedId = viewModel.options[indexPath.row].id
        viewModel.selectedId = selectedId
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.setSound(soundId: selectedId)
        optionTableView.reloadData()

        let manager = audioManager
        let file = SoundOptions(selectedId).fileName
        AudioManager.playbackQueue.async {
            do {
                try manager.stop()
                try manager.setPlayer(fileName: file, fileExtension: "mp3")
                try manager.play(numberOfLoops: 0)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: "Couldn't preview sound", message: "Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}

extension SoundSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: OptionSelectionViewCell.reuseIdentifier, for: indexPath) as? OptionSelectionViewCell {
            let option = viewModel.options[indexPath.row]
            cell.configure(optionLabelText: option.title, isSelected: option.selected)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
