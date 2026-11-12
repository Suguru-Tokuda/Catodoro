//
//  AlertOnboardingViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class AlertOnboardingViewControllerTests: XCTestCase {
    func test_view_expectAllowTitleForEachKind() {
        let cases: [(AlertOnboardingViewModel.Kind, String)] = [
            (.alarm, AppStrings.Onboarding.allowAlarms),
            (.notification, AppStrings.Onboarding.allowNotifications),
        ]
        for (kind, title) in cases {
            let view = AlertOnboardingView(kind: kind)
            XCTAssertEqual(view.testHooks.allowButton.titleText, title)
            XCTAssertEqual(view.testHooks.notNowButton.titleText, AppStrings.Onboarding.notNow)
            XCTAssertTrue(allLabelTexts(in: view).contains(AppStrings.Onboarding.alertHeadline))
        }
        XCTAssertTrue(allLabelTexts(in: AlertOnboardingView(kind: .alarm)).contains(AppStrings.Onboarding.alarmDescription))
        XCTAssertTrue(allLabelTexts(in: AlertOnboardingView(kind: .notification)).contains(AppStrings.Onboarding.notificationDescription))
    }

    func test_view_expectBenefitsForEachKind() {
        for kind in [AlertOnboardingViewModel.Kind.alarm, .notification] {
            let card = AlertOnboardingView(kind: kind).testHooks.benefitsCard
            let texts = card?.rows.compactMap { $0.testHooks.textLabel.text }
            XCTAssertEqual(texts, AlertOnboardingView.benefits(for: kind).map(\.text), "\(kind)")
        }
    }

    func test_render_expectButtonsDisabledAndSpinnerWhileBusy() {
        let view = AlertOnboardingView(kind: .alarm)

        view.render(isBusy: true)
        XCTAssertFalse(view.testHooks.allowButton.isEnabled)
        XCTAssertFalse(view.testHooks.notNowButton.isEnabled)
        XCTAssertTrue(view.testHooks.spinner.isAnimating)

        view.render(isBusy: false)
        XCTAssertTrue(view.testHooks.allowButton.isEnabled)
        XCTAssertTrue(view.testHooks.notNowButton.isEnabled)
        XCTAssertFalse(view.testHooks.spinner.isAnimating)
    }

    func test_allowTap_expectPermissionAskedThenCompletion() async {
        let countdown = MockCountdown()
        let preferences = MockPreferences()
        let controller = AlertOnboardingViewController(
            viewModel: AlertOnboardingViewModel(countdown: countdown, preferences: preferences, kind: .alarm))
        var completed = false
        controller.onCompletion { completed = true }
        controller.loadViewIfNeeded()

        controller.testHooks.alertOnboardingView.testHooks.allowButton.sendActions(for: .touchUpInside)

        await waitUntil { completed }
        XCTAssertEqual(countdown.requestedBackends, [.alarmKit])
        XCTAssertEqual(preferences.alertStyle, .alarm)
    }

    func test_notNowTap_expectCompletionWithoutPrompt() {
        let countdown = MockCountdown()
        let preferences = MockPreferences()
        let controller = AlertOnboardingViewController(
            viewModel: AlertOnboardingViewModel(countdown: countdown, preferences: preferences, kind: .notification))
        var completed = false
        controller.onCompletion { completed = true }
        controller.loadViewIfNeeded()

        controller.testHooks.alertOnboardingView.testHooks.notNowButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(completed)
        XCTAssertTrue(countdown.requestedBackends.isEmpty)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
    }

    private func allLabelTexts(in view: UIView) -> [String] {
        var texts: [String] = []
        func walk(_ view: UIView) {
            if let label = view as? UILabel, let text = label.text { texts.append(text) }
            view.subviews.forEach(walk)
        }
        walk(view)
        return texts
    }
}
