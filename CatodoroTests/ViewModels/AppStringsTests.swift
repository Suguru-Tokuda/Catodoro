import Foundation
import Testing
import CatodoroShared
@testable import Catodoro

struct AppStringsTests {
    @Test func catalogIsPackagedInSharedFramework() throws {
        let bundle = try #require(Bundle(identifier: "com.sugurutokuda.CatodoroShared"))
        // Read the compiled catalog directly: defaultValue must not hide a missing resource.
        #expect(bundle.localizedString(forKey: "common.focusTime", value: nil, table: nil) == "Focus time")
        #expect(String(localized: AppStrings.Resources.restYourPaws) == AppStrings.Common.restYourPaws)
    }

    @Test func sessionCopyUsesPluralRules() {
        #expect(AppStrings.Timer.focusSessionCount(1) == "1 focus session")
        #expect(AppStrings.Timer.focusSessionCount(2) == "2 focus sessions")
        #expect(AppStrings.Timer.sessionsCompleted(1) == "1 session completed")
        #expect(AppStrings.Timer.sessionsCompleted(0) == "0 sessions completed")
    }

    @Test func templatesPreserveArguments() {
        #expect(AppStrings.Timer.nextSession(2, 4) == "Next: session 2 of 4")
        #expect(AppStrings.Presets.startNamedPreset("Mochi") == "Start Mochi")
        #expect(AppStrings.Presets.routineSummary("25 min", "5 min", 4)
                == "25 min focus · 5 min break · 4 sessions")
    }

    @Test func newCatalogKeysAreCompiledIntoSharedFramework() throws {
        let bundle = try #require(Bundle(identifier: "com.sugurutokuda.CatodoroShared"))
        let expected = [
            "alarm.skipBreakButton": "Skip break",
            "alarm.breakOver": "Break's over",
            "alertStyles.liveActivityTitle": "Live Activity Only",
            "alertStyles.openSettings": "Open Settings",
            "countdownErrors.notAuthorized": "Permission was not granted.",
            "notifications.focusCompleteBreakNext": "Focus complete · Break next",
            "common.end": "End",
            "onboarding.allowAlarms": "Allow Alarms",
        ]
        for (key, value) in expected {
            #expect(bundle.localizedString(forKey: key, value: nil, table: nil) == value, "\(key)")
        }
    }

    @Test func alarmResourcesResolve() {
        #expect(String(localized: AppStrings.Alarm.focusComplete) == "Focus complete")
        #expect(String(localized: AppStrings.Alarm.focusCountdown(2, of: 4)) == "Focus · 2 of 4")
        #expect(String(localized: AppStrings.Alarm.catnapBreak) == AppStrings.Common.catnapBreak)
    }

    @Test func alertStyleCopyComesFromAppStrings() {
        #expect(AlertStyle.alarm.title == AppStrings.AlertStyles.alarmTitle)
        #expect(AlertStyle.notification.detail == AppStrings.AlertStyles.notificationDetail)
        #expect(AlertStyle.liveActivity.title == "Live Activity Only")
    }

    @Test func countdownErrorsUseAppStrings() {
        #expect(CountdownError.alreadyRunning.errorDescription == AppStrings.CountdownErrors.alreadyRunning)
        #expect(CountdownError.notAuthorized.errorDescription == AppStrings.CountdownErrors.notAuthorized)
    }

    @Test func diagnosticsIncludeTheUnderlyingError() {
        struct Boom: Error, CustomStringConvertible { var description: String { "boom" } }
        #expect(AppStrings.Diagnostics.localStoreLoadFailed(Boom()).hasSuffix("boom"))
    }
}
