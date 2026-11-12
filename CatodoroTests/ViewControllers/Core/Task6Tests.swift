//
//  Task6Tests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 10/11/26.
//

import ActivityKit
import AppIntents
import CatodoroShared
import SwiftUI
import XCTest
@testable import Catodoro

@MainActor
final class Task6Tests: XCTestCase {
    func test_firstSoundPreviewCanStopFreshManagerAndLoadEveryBundledSound() throws {
        let manager = AudioManager()
        XCTAssertNoThrow(try manager.stop())
        XCTAssertNoThrow(try manager.stop())

        for sound in SoundOptions.allCases {
            XCTAssertNotNil(Bundle.main.url(forResource: sound.fileName, withExtension: "mp3"))
            XCTAssertNoThrow(try manager.setPlayer(fileName: sound.fileName, fileExtension: "mp3"))
        }
    }

    private var instant = Date(timeIntervalSince1970: 1000)

    func test_liveActivityPreferenceDefaultsOnAndPersistsBothValues() throws {
        let suite = "Task6-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertTrue(CatodoroPreferences(userDefaults: defaults).liveActivityEnabled)
        let preferences = CatodoroPreferences(userDefaults: defaults)
        preferences.setLiveActivityEnabled(false)
        XCTAssertFalse(CatodoroPreferences(userDefaults: defaults).liveActivityEnabled)
        preferences.setLiveActivityEnabled(true)
        XCTAssertTrue(CatodoroPreferences(userDefaults: defaults).liveActivityEnabled)
    }

    func test_settingsKeepsPreferenceWhenSystemDisallowsActivitiesAndUsesSavedSelections() {
        let preferences = MockPreferences()
        preferences.setSound(.kitty)
        let settings = SettingsViewModel(preferences: preferences, activitiesAuthorized: { false })
        settings.selectColor(.neonPink)
        settings.setLiveActivityEnabled(true)
        XCTAssertFalse(settings.state.activitiesAuthorized)
        XCTAssertTrue(settings.state.liveActivityEnabled)
        XCTAssertEqual(settings.state.color, .neonPink)
        XCTAssertEqual(settings.state.sound, .kitty)
        XCTAssertEqual(preferences.color, "nPink")
    }

    // MARK: - Live Activity / alarm buttons → CountdownIntentRouter

    func test_intentsRouteToCountdownHandlerWithTheirAlarmID() async throws {
        let countdown = MockCountdown()
        let previous = CountdownIntentRouter.handler
        CountdownIntentRouter.handler = countdown
        defer { CountdownIntentRouter.handler = previous }

        _ = try await PlayTimerIntent(alarmID: "a1").perform()
        _ = try await SkipBreakIntent(alarmID: "a2").perform()
        _ = try await AdvanceIntent(alarmID: "a3").perform()
        _ = try await RepeatTimerIntent(alarmID: "a4").perform()
        _ = try await StopTimerIntent(alarmID: "a5").perform()
        _ = try await EndCycleIntent(alarmID: "a6").perform()

        XCTAssertEqual(countdown.calls, [
            .togglePauseResume("a1"),
            .skipBreak("a2"),
            .advance("a3"),
            .restartCycle("a4"),
            .endCycle("a5"),
            .endCycle("a6"),
        ])
    }

    func test_intentsPassHandlerErrorsBack() async {
        let countdown = MockCountdown()
        countdown.actionError = CountdownError.invalidSteps
        let previous = CountdownIntentRouter.handler
        CountdownIntentRouter.handler = countdown
        defer { CountdownIntentRouter.handler = previous }

        do {
            _ = try await PlayTimerIntent(alarmID: "a1").perform()
            XCTFail("Expected the handler's error")
        } catch CountdownError.invalidSteps {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_intentsWithoutHandlerDoNothing() async throws {
        let previous = CountdownIntentRouter.handler
        CountdownIntentRouter.handler = nil
        defer { CountdownIntentRouter.handler = previous }

        _ = try await PlayTimerIntent(alarmID: "a1").perform()
        _ = try await StopTimerIntent(alarmID: "a1").perform()
    }

    func test_appDelegateStyleWiring_routesToDependenciesCountdown() async throws {
        let dependencies = TestDependencies()
        defer { dependencies.tearDown() }
        let previous = CountdownIntentRouter.handler
        CountdownIntentRouter.handler = dependencies.app.countdown
        defer { CountdownIntentRouter.handler = previous }

        _ = try await SkipBreakIntent(alarmID: "b1").perform()

        XCTAssertEqual(dependencies.countdown.calls, [.skipBreak("b1")])
    }

    func test_liveActivityManagerRefusesToStartWhenActivitiesAreDisabled() {
        let manager = LiveActivityManager(activitiesEnabled: { false })
        XCTAssertThrowsError(try manager.startLiveActivity(name: "Catodoro", currentTimerValue: 10,
                                                          endTime: instant + 10, intervals: 3, interval: 1,
                                                          timerType: .main, timerStatus: .playing,
                                                          phaseDuration: 10, accentCode: nil))
        XCTAssertFalse(manager.hasLiveActivity())
        manager.endLiveActivity()
    }

    func test_skipControlOnlyAppearsDuringBreakAndRoutesAction() {
        let view = TimerView(frame: .zero)
        var skips = 0
        view.onSkipBreakTap = { skips += 1 }
        func state(_ isBreak: Bool, _ status: TimerStatus) -> TimerPresentationState {
            .init(isBreak: isBreak, status: status, sessionIndex: 1, sessionCount: 3,
                  remainingDuration: 5, phaseDuration: 5)
        }
        view.configure(state(false, .playing))
        XCTAssertTrue(view.testHooks.skipBreakButton.isHidden)
        view.configure(state(true, .paused))
        XCTAssertFalse(view.testHooks.skipBreakButton.isHidden)
        view.testHooks.skipBreakButton.sendActions(for: .touchUpInside)
        XCTAssertEqual(skips, 1)
        view.configure(state(true, .finished))
        XCTAssertTrue(view.testHooks.skipBreakButton.isHidden)
    }

    func test_widgetStateUsesCatAssetsAndCorrectBreakActions() throws {
        let state = TimerAttributes.ContentState(currentTimerValue: 252, endTime: instant + 252,
                                                intervals: 4, interval: 2, timerType: .interval,
                                                timerStatus: .paused, phaseDuration: 300)
        XCTAssertTrue(state.canSkipBreak)
        XCTAssertEqual(state.artworkName, "CatBreak")
        XCTAssertEqual(state.phaseTitle, "Paused")
        XCTAssertEqual(state.sessionSummary, "Next: session 3 of 4")
        XCTAssertEqual(state.countdown, "04:12")
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        legacy.removeValue(forKey: "phaseDuration")
        legacy.removeValue(forKey: "accentCode")
        let decoded = try JSONDecoder().decode(TimerAttributes.ContentState.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(decoded.phaseDuration)
        XCTAssertEqual(decoded.artworkName, "CatBreak")
    }

    func test_widgetArtworkHasBoundedNativeSizeAndTransparency() throws {
        let extensionURL = Bundle.main.bundleURL
            .appendingPathComponent("PlugIns/CatodoroWidgetExtension.appex")
        let widgetBundle = try XCTUnwrap(Bundle(url: extensionURL))

        for name in ["CatFocus", "CatBreak", "CatPlayful", "CatPaw"] {
            let image = try XCTUnwrap(UIImage(named: "Activity" + name, in: widgetBundle,
                                             compatibleWith: nil), name)
            let maximum: CGFloat = name == "CatPaw" ? 20 : 76
            XCTAssertLessThanOrEqual(image.size.width, maximum)
            XCTAssertLessThanOrEqual(image.size.height, maximum)
            XCTAssertGreaterThan(image.scale, 1)
            let alpha = try XCTUnwrap(image.cgImage).alphaInfo
            XCTAssertTrue([CGImageAlphaInfo.first, .last, .premultipliedFirst,
                           .premultipliedLast].contains(alpha), name)
        }
    }

    func test_progressLayoutHeightStaysConstantAcrossPauseResumeAndCompletion() {
        let end = Date.now + 252
        for width in [CGFloat(180), 250, 370] {
            let host = UIHostingController(rootView: ActivityProgress(state:
                .init(currentTimerValue: 252, endTime: end, intervals: 4, interval: 1,
                      timerType: .main, timerStatus: .playing, phaseDuration: 300)))
            for status in [TimerStatus.playing, .paused, .playing, .finished] {
                host.rootView = ActivityProgress(state:
                    .init(currentTimerValue: status == .finished ? 0 : 252, endTime: end,
                          intervals: 4, interval: 1, timerType: .main,
                          timerStatus: status, phaseDuration: 300))
                let size = host.sizeThatFits(in: CGSize(width: width, height: 1000))
                XCTAssertEqual(size.height, 4, accuracy: 0.01, "\(status) at width \(width)")
            }
        }
    }

    func test_renderLiveActivityCardsAndExpandedIsland() throws {
        let end = Date.now + 252
        for scheme in [ColorScheme.light, .dark] {
            for phase in [TimerType.main, .interval] {
                var cardHeight: CGFloat?
                var islandHeight: CGFloat?
                for status in [TimerStatus.playing, .paused] {
                    let state = TimerAttributes.ContentState(currentTimerValue: 252, endTime: end,
                                                            intervals: 4, interval: 2, timerType: phase,
                                                            timerStatus: status, phaseDuration: 300)
                    let view = TimerLiveActivityCard(state: state).frame(width: 370)
                        .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 3
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertGreaterThan(image.size.height, 100)
                    if let cardHeight {
                        XCTAssertEqual(image.size.height, cardHeight, accuracy: 0.01,
                                       "Lock Screen layout changed on pause: \(phase), \(scheme)")
                    }
                    cardHeight = image.size.height
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "Activity-\(phase.rawValue)-\(scheme)-\(status)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                    let islandRenderer = ImageRenderer(content: ExpandedTimerActivity(state: state)
                        .padding(16).frame(width: 350).background(.black).environment(\.colorScheme, scheme))
                    islandRenderer.scale = 3
                    let islandImage = try XCTUnwrap(islandRenderer.uiImage)
                    if let islandHeight {
                        XCTAssertEqual(islandImage.size.height, islandHeight, accuracy: 0.01,
                                       "Expanded Island layout changed on pause: \(phase), \(scheme)")
                    }
                    islandHeight = islandImage.size.height
                    let islandAttachment = XCTAttachment(image: islandImage)
                    islandAttachment.name = "Expanded-Island-\(phase.rawValue)-\(scheme)-\(status)"
                    islandAttachment.lifetime = .keepAlways
                    add(islandAttachment)
                }
            }
        }
    }
}
