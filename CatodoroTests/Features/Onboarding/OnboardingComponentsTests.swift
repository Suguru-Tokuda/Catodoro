//
//  OnboardingComponentsTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import XCTest
@testable import Catodoro

@MainActor
final class OnboardingComponentsTests: XCTestCase {
    // MARK: Label

    func test_label_expectCenteredWrappingDynamicType() {
        let label = OnboardingLabel(text: "Hello", style: .title1, weight: .bold, color: .red)

        XCTAssertEqual(label.text, "Hello")
        XCTAssertEqual(label.numberOfLines, 0)
        XCTAssertEqual(label.textAlignment, .center)
        XCTAssertTrue(label.adjustsFontForContentSizeCategory)
        XCTAssertEqual(label.textColor, .red)
        XCTAssertEqual(label.font, CatTheme.font(.title1, weight: .bold))
    }

    func test_label_expectThemeTextColorByDefault() {
        XCTAssertEqual(OnboardingLabel(text: "", style: .body).textColor, CatTheme.text)
    }

    // MARK: Image

    func test_image_expectDecorativeFixedHeight() {
        let image = OnboardingImageView(imageName: "CatCloud", height: 120)

        XCTAssertNotNil(image.image)
        XCTAssertFalse(image.isAccessibilityElement)
        XCTAssertEqual(image.contentMode, .scaleAspectFit)
        XCTAssertTrue(image.constraints.contains {
            $0.firstAttribute == .height && $0.constant == 120 && $0.secondItem == nil
        })
    }

    // MARK: Button

    func test_button_expectTitleAndColorsForEachKind() {
        let primary = OnboardingButton(title: "Go", kind: .primary)
        let secondary = OnboardingButton(title: "Later", kind: .secondary)

        XCTAssertEqual(primary.titleText, "Go")
        XCTAssertEqual(primary.configuration?.baseBackgroundColor, CatTheme.accent(.neonBlue))
        XCTAssertEqual(primary.configuration?.baseForegroundColor, CatTheme.onAccent)
        XCTAssertEqual(secondary.titleText, "Later")
        XCTAssertEqual(secondary.configuration?.baseBackgroundColor, CatTheme.selection)
        XCTAssertEqual(secondary.configuration?.baseForegroundColor, CatTheme.accent(.neonBlue))
    }

    func test_button_titleTextChangesConfigurationTitle() {
        let button = OnboardingButton(title: "Go", kind: .primary)

        button.titleText = "Retry"

        XCTAssertEqual(button.configuration?.title, "Retry")
    }

    func test_button_onTapRunsHandler() {
        let button = OnboardingButton(title: "Go", kind: .primary)
        var taps = 0
        button.onTap { taps += 1 }

        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(taps, 1)
    }

    // MARK: Benefits

    func test_benefitRow_expectSymbolAndLeftAlignedText() {
        let row = OnboardingBenefitRowView(symbolName: "wifi.slash", text: "Offline")

        XCTAssertEqual(row.testHooks.iconView.image, UIImage(systemName: "wifi.slash"))
        XCTAssertFalse(row.testHooks.iconView.isAccessibilityElement)
        XCTAssertEqual(row.testHooks.textLabel.text, "Offline")
        XCTAssertEqual(row.testHooks.textLabel.textAlignment, .left)
    }

    func test_benefitsCard_expectOneRowPerBenefitInOrder() {
        let benefits: [OnboardingBenefitsCardView.Benefit] = [
            .init(symbolName: "bell", text: "One"),
            .init(symbolName: "lock", text: "Two"),
        ]

        let card = OnboardingBenefitsCardView(benefits: benefits)

        XCTAssertEqual(card.rows.map { $0.testHooks.textLabel.text }, ["One", "Two"])
        XCTAssertEqual(card.backgroundColor, CatTheme.card)
        XCTAssertEqual(card.layer.cornerRadius, CatTheme.cardRadius)
    }

    // MARK: Content

    func test_contentView_keepsArrangedOrder() {
        let content = OnboardingContentView()
        let first = UIView()
        let second = UIView()

        content.addArrangedSubview(first)
        content.addArrangedSubviews([second])

        XCTAssertEqual(content.arrangedSubviews, [first, second])
    }

    // MARK: Sync step view

    func test_syncView_renderShowsErrorAndRetryTitle() {
        let view = SyncOnboardingView()

        view.render(isBusy: false, error: "Nope")

        XCTAssertEqual(view.testHooks.enableButton.titleText, AppStrings.Onboarding.retryICloudSync)
        XCTAssertEqual(view.testHooks.errorLabel.text, "Nope")
        XCTAssertFalse(view.testHooks.errorLabel.isHidden)

        view.render(isBusy: true, error: nil)

        XCTAssertEqual(view.testHooks.enableButton.titleText, AppStrings.Onboarding.enableICloudSync)
        XCTAssertTrue(view.testHooks.errorLabel.isHidden)
        XCTAssertFalse(view.testHooks.enableButton.isEnabled)
        XCTAssertFalse(view.testHooks.localButton.isEnabled)
        XCTAssertTrue(view.testHooks.spinner.isAnimating)
    }

    func test_syncView_buttonsCallTheirHandlers() {
        let view = SyncOnboardingView()
        var events: [String] = []
        view.onEnableSync = { events.append("sync") }
        view.onContinueLocally = { events.append("local") }

        view.testHooks.enableButton.sendActions(for: .touchUpInside)
        view.testHooks.localButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(events, ["sync", "local"])
    }
}
