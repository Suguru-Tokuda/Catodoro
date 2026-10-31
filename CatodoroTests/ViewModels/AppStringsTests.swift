import Foundation
import Testing
import CatodoroShared

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
}
