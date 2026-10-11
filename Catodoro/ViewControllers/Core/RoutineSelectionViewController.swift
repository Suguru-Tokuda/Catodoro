//
//  RoutineSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

enum RoutineSelection {
    case focus
    case catnap
    case sessions
}

class RoutineSelectionViewController: UIViewController {
    var selectionView: RoutineSelectionView {
        view as! RoutineSelectionView
    }

    var confirmButton: UIButton {
        selectionView.confirmButton
    }

    func makeSelectionView() -> RoutineSelectionView {
        RoutineSelectionView()
    }

    override func loadView() {
        view = makeSelectionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        selectionView.onClose = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

extension UIViewController {
    func makeRoutineSelectionEditor(_ selection: RoutineSelection,
                                 configuration: TimerConfigModel,
                                 onCommit: @escaping (TimerConfigModel) -> Void) -> UIViewController {
        let editor: UIViewController

        switch selection {
        case .focus, .catnap:
            let durationEditor = DurationSelectionViewController(mode: selection,
                duration: selection == .focus ? configuration.mainTimer : configuration.interval)
            durationEditor.onCommit = { timer in
                var updated = configuration

                if selection == .focus {
                    updated.mainTimer = timer
                } else {
                    updated.interval = timer
                }

                onCommit(updated)
            }
            editor = durationEditor

        case .sessions:
            let sessionEditor = SessionSelectionViewController(configuration: configuration)
            sessionEditor.onCommit = { count in
                var updated = configuration
                updated.intervals = count
                onCommit(updated)
            }
            editor = sessionEditor
        }

        return editor
    }

    func presentRoutineSelection(_ selection: RoutineSelection,
                                 configuration: TimerConfigModel,
                                 onCommit: @escaping (TimerConfigModel) -> Void) {
        let editor = makeRoutineSelectionEditor(selection, configuration: configuration, onCommit: onCommit)
        let navigation = BaseNavigationController(rootViewController: editor)
        navigation.modalPresentationStyle = traitCollection.userInterfaceIdiom == .pad ? .formSheet : .pageSheet
        navigation.preferredContentSize = CGSize(width: 500, height: 520)

        if let sheet = navigation.sheetPresentationController {
            let initialHeight: CGFloat = selection == .sessions ? 580 : 520
            let contentDetent = UISheetPresentationController.Detent.Identifier("routineSelection")
            sheet.detents = [
                .custom(identifier: contentDetent) { context in
                    min(initialHeight, context.maximumDetentValue)
                },
                .large()
            ]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.selectedDetentIdentifier = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
                ? .large : contentDetent
        }

        present(navigation, animated: true)
    }
}
