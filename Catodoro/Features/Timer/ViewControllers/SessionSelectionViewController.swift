//
//  SessionSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

final class SessionSelectionViewController: RoutineSelectionViewController {
    private var configuration: TimerConfigModel
    private(set) var draftCount: Int
    var onCommit: ((Int) -> Void)?
    private var hasCommitted = false

    private let sessionView = SessionSelectionView()

    init(configuration: TimerConfigModel) {
        self.configuration = configuration
        self.draftCount = min(20, max(1, configuration.intervals))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func makeSelectionView() -> RoutineSelectionView {
        sessionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Focus sessions"
        sessionView.onCountChange = { [weak self] delta in
            self?.adjustCount(by: delta)
        }
        sessionView.onConfirm = { [weak self] in
            self?.confirm()
        }
        render()
    }

    func adjustCount(by delta: Int) {
        draftCount = min(20, max(1, draftCount + min(20, max(-20, delta))))
        render()
        sessionView.announceCount(draftCount)
    }

    func confirm() {
        guard !hasCommitted, (1...20).contains(draftCount) else {
            return
        }

        hasCommitted = true
        onCommit?(draftCount)
        dismiss(animated: true)
    }

    private func render() {
        configuration.intervals = draftCount
        let focus = "\(TimerConfigModel.durationSummary(configuration.mainTimer.duration)) × \(draftCount)"
        let breaks = configuration.interval.duration > 0 ? draftCount - 1 : 0
        let breakSummary = breaks == 0 ? "No breaks" : "\(TimerConfigModel.durationSummary(configuration.interval.duration)) × \(breaks)"
        sessionView.render(count: draftCount, focusSummary: focus, breakSummary: breakSummary,
                           totalSummary: TimerConfigModel.durationSummary(configuration.totalDuration))
    }

    #if DEBUG
    var focusSummary: String? {
        sessionView.focusSummary
    }

    var breakSummary: String? {
        sessionView.breakSummary
    }

    var totalSummary: String? {
        sessionView.totalSummary
    }

    var canDecrease: Bool {
        sessionView.canDecrease
    }

    var canIncrease: Bool {
        sessionView.canIncrease
    }
    #endif
}
