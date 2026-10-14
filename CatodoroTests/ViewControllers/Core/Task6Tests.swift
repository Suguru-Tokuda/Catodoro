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

    private func timer(preferences: CatodoroPreferencesProtocol? = nil,
                       activities: LiveActivityManaging? = nil, count: Int = 3) -> TimerViewModel {
        let timer = TimerViewModel(audioManager: MockAudioManager(), preferences: preferences,
                                   liveActivityManager: activities, now: { [unowned self] in self.instant },
                                   schedulesTicks: false, applicationIsActive: { true })
        timer.configure(totalDuration: 10, intervalDuration: 5, intervals: count)
        timer.startTimer()
        return timer
    }

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

    func test_skipBreakIsIgnoredDuringFocusAndAfterCompletion() {
        let model = timer(count: 1)
        let original = model.presentationSubject.value
        model.skipBreak()
        XCTAssertEqual(model.presentationSubject.value, original)
        instant += 10
        model.refresh()
        model.skipBreak()
        XCTAssertEqual(model.presentationSubject.value.status, .finished)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 1)
    }

    func test_skipPausedBreakStartsFullNextFocusAndPreservesRemainingSessions() {
        let model = timer()
        instant += 10
        model.refresh()
        model.pauseTimer()
        XCTAssertTrue(model.isBreak)
        model.skipBreak()
        let state = model.presentationSubject.value
        XCTAssertFalse(state.isBreak)
        XCTAssertEqual(state.status, .playing)
        XCTAssertEqual(state.sessionIndex, 2)
        XCTAssertEqual(state.remainingDuration, 10)
        instant += 10
        model.refresh()
        XCTAssertTrue(model.isBreak)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 2)
    }

    func test_skipReconcilesExpiredBreakWithoutSkippingNewFocus() {
        let model = timer()
        instant += 10
        model.refresh()
        instant += 7
        model.skipBreak()
        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 2)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 8)
    }

    func test_liveActivityIntentUsesSameSkipActionAndUpdatesActivity() async throws {
        let activity = MockLiveActivityManager()
        let model = timer(activities: activity)
        instant += 10
        model.refresh()
        _ = try await SkipBreakIntent().perform()
        await model.testHooks.flushLiveActivityOperations()
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 2)
        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(activity.lastState?.timerType, .main)
        XCTAssertEqual(activity.lastState?.currentTimerValue, 10)
        XCTAssertEqual(activity.lastState?.phaseDuration, 10)
    }

    func test_disabledPreferencePreventsActivityWithoutStoppingTimer() {
        let preferences = MockPreferences()
        preferences.setLiveActivityEnabled(false)
        let activities = MockLiveActivityManager()
        let model = timer(preferences: preferences, activities: activities)
        XCTAssertFalse(activities.didStartLiveActivity)
        XCTAssertEqual(model.presentationSubject.value.status, .playing)
    }

    func test_toggleDuringPausedRoutineEndsAndRecreatesActivityWithCurrentState() async {
        let preferences = MockPreferences()
        let activities = MockLiveActivityManager()
        let model = timer(preferences: preferences, activities: activities)
        model.pauseTimer()
        let ended = expectation(description: "Activity ends when disabled")
        activities.onEnd = { ended.fulfill() }
        preferences.setLiveActivityEnabled(false)
        await fulfillment(of: [ended], timeout: 1)
        XCTAssertEqual(model.presentationSubject.value.status, .paused)
        let started = expectation(description: "Activity restarts when enabled")
        activities.onStart = { started.fulfill() }
        preferences.setLiveActivityEnabled(true)
        await fulfillment(of: [started], timeout: 1)
        await model.testHooks.flushLiveActivityOperations()
        XCTAssertEqual(activities.lastState?.timerStatus, .paused)
        XCTAssertEqual(activities.lastState?.currentTimerValue, 10)
        activities.onEnd = nil
        activities.onStart = nil
    }

    func test_authorizationFailureIsReportedAndTimerRemainsUsable() {
        let activities = MockLiveActivityManager()
        activities.startError = LiveActivityError.disabled
        let model = timer(activities: activities)
        XCTAssertNotNil(model.liveActivityError)
        XCTAssertEqual(model.presentationSubject.value.status, .playing)
        model.pauseTimer()
        XCTAssertEqual(model.presentationSubject.value.status, .paused)
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
        view.render(state(false, .playing))
        XCTAssertTrue(view.testHooks.skipBreakButton.isHidden)
        view.render(state(true, .paused))
        XCTAssertFalse(view.testHooks.skipBreakButton.isHidden)
        view.testHooks.skipBreakButton.sendActions(for: .touchUpInside)
        XCTAssertEqual(skips, 1)
        view.render(state(true, .finished))
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

    func test_renderLiveActivityCardsAndExpandedIsland() throws {
        for scheme in [ColorScheme.light, .dark] {
            for phase in [TimerType.main, .interval] {
                let state = TimerAttributes.ContentState(currentTimerValue: 252, endTime: .now + 252,
                                                        intervals: 4, interval: 2, timerType: phase,
                                                        timerStatus: .paused, phaseDuration: 300)
                let view = TimerLiveActivityCard(state: state).frame(width: 370)
                    .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 3
                let image = try XCTUnwrap(renderer.uiImage)
                XCTAssertGreaterThan(image.size.height, 100)
                let attachment = XCTAttachment(image: image)
                attachment.name = "Activity-\(phase.rawValue)-\(scheme)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        let state = TimerAttributes.ContentState(currentTimerValue: 252, endTime: .now + 252,
                                                intervals: 4, interval: 2, timerType: .interval,
                                                timerStatus: .paused, phaseDuration: 300)
        let renderer = ImageRenderer(content: ExpandedTimerActivity(state: state)
            .padding(16).frame(width: 350).background(.black).environment(\.colorScheme, .dark))
        renderer.scale = 3
        let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
        attachment.name = "Expanded Island break"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
