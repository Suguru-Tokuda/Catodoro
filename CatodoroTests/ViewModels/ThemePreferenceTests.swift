import Combine
import UIKit
import XCTest
@testable import Catodoro

@MainActor
final class ThemePreferenceTests: XCTestCase {
    func testDefaultsToSystemAndPersistsEverySelection() throws {
        let suite = "Theme-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = CatodoroPreferences(userDefaults: defaults)
        XCTAssertEqual(preferences.theme, .system)
        var published: [ThemeOption] = []
        let subscription = preferences.themePublisher.sink { published.append($0) }
        for theme in [ThemeOption.dark, .light, .system] {
            let settings = SettingsViewModel(preferences: preferences, activitiesAuthorized: { false })
            settings.selectTheme(theme)
            XCTAssertEqual(settings.state.theme, theme)
            XCTAssertEqual(CatodoroPreferences(userDefaults: defaults).theme, theme)
            XCTAssertEqual(published.last, theme)
        }
        withExtendedLifetime(subscription) {}
        XCTAssertEqual(ThemeOption.system.interfaceStyle, .unspecified)
        XCTAssertEqual(ThemeOption.light.interfaceStyle, .light)
        XCTAssertEqual(ThemeOption.dark.interfaceStyle, .dark)
    }

    func testUnknownSavedThemeFallsBackToSystem() throws {
        let suite = "Theme-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("unknown", forKey: "theme")
        XCTAssertEqual(CatodoroPreferences(userDefaults: defaults).theme, .system)
    }
}
