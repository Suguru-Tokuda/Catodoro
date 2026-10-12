//
//  CatodoroUITests.swift
//  CatodoroUITests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import XCTest

final class CatodoroUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func test_presetCreateEditAndPersist() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Presets"].tap()
        app.navigationBars.buttons["Add"].tap()
        let name = "Study " + String(UUID().uuidString.prefix(6))
        let field = app.textFields["presetName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["savePreset"].isEnabled)
        field.tap()
        field.typeText(name + "\n")
        app.buttons["presetImage"].tap()
        app.buttons["CatStretching"].tap()
        app.buttons["Focus time"].tap()
        app.buttons["50 min"].tap()
        app.buttons["Set focus time"].tap()
        capture(app, name: "Preset editor light")
        app.buttons["savePreset"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        capture(app, name: "Preset cards light")
        app.staticTexts[name].tap()
        XCTAssertEqual(app.textFields["presetName"].value as? String, name)
        XCTAssertEqual(app.buttons["presetImage"].value as? String, "Stretching cat")
        XCTAssertEqual(app.buttons["Focus time"].value as? String, "50 min")
        app.buttons["presetImage"].tap()
        capture(app, name: "Preset image picker")
        app.buttons["CatSleeping"].tap()
        app.buttons["savePreset"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["Presets"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        app.staticTexts[name].tap()
        XCTAssertEqual(app.buttons["presetImage"].value as? String, "Sleeping cat")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Start " + name].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        app.buttons["End session"].tap()
        XCTAssertTrue(app.tabBars.buttons["Presets"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Presets"].isSelected)
        XCTAssertTrue(app.staticTexts[name].exists)
        app.staticTexts[name].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts[name].exists)

        app.tabBars.buttons["Focus"].tap()
        app.buttons["Start focusing"].tap()
        XCTAssertTrue(app.buttons["End session"].waitForExistence(timeout: 5))
        app.buttons["End session"].tap()
        XCTAssertTrue(app.tabBars.buttons["Focus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Focus"].isSelected)
    }

    @MainActor
    func test_settingsPersistAccentSoundAndActivityPreference() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Make yourself at home"].waitForExistence(timeout: 5))
        app.buttons["nPink"].tap()
        XCTAssertEqual(app.buttons["nPink"].value as? String, "Selected")
        let activity = app.switches["liveActivityToggle"]
        let original = activity.value as? String
        activity.tap()
        let updated = activity.value as? String
        XCTAssertNotEqual(original, updated)
        app.buttons["Timer sound"].tap()
        app.staticTexts["Kitty"].tap()
        capture(app, name: "Sound selection")
        app.navigationBars.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["Timer sound"].value as? String, "Kitty")
        capture(app, name: "Settings")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertEqual(app.buttons["nPink"].value as? String, "Selected")
        XCTAssertEqual(app.switches["liveActivityToggle"].value as? String, updated)
        XCTAssertEqual(app.buttons["Timer sound"].value as? String, "Kitty")
        app.buttons["nBlue"].tap()
        if app.switches["liveActivityToggle"].value as? String == "0" {
            app.switches["liveActivityToggle"].tap()
        }
    }

    @MainActor
    func test_skipPausedBreakStartsNextFocus() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Focus time"].tap()
        setDuration(app, seconds: 5)
        app.buttons["Set focus time"].tap()
        app.buttons["Catnap break"].tap()
        setDuration(app, seconds: 30)
        app.buttons["Set break time"].tap()
        app.buttons["Sessions"].tap()
        for _ in 0..<19 {
            if app.staticTexts["2 focus sessions"].exists { break }
            app.buttons["Fewer sessions"].tap()
        }
        XCTAssertTrue(app.staticTexts["2 focus sessions"].exists)
        app.buttons["Set sessions"].tap()
        app.buttons["Start focusing"].tap()
        XCTAssertFalse(app.buttons["skipBreak"].exists)
        XCTAssertTrue(app.staticTexts["CATNAP BREAK"].waitForExistence(timeout: 10))
        app.buttons["Pause"].tap()
        capture(app, name: "Break with skip")
        app.buttons["skipBreak"].tap()
        XCTAssertTrue(app.staticTexts["FOCUS SESSION"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 of 2"].exists)
        XCTAssertFalse(app.buttons["skipBreak"].exists)
        app.buttons["End session"].tap()
        XCTAssertTrue(app.tabBars.buttons["Focus"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func test_routineSheetsCommitCancelAndReopen() throws {
        let app = XCUIApplication()
        app.launch()
        let focusRow = app.buttons["Focus time"]
        XCTAssertTrue(focusRow.waitForExistence(timeout: 5))
        XCTAssertEqual(focusRow.value as? String, "25 min")
        capture(app, name: "Focus setup")
        focusRow.tap()
        app.buttons["50 min"].tap()
        app.buttons["Close"].tap()
        XCTAssertEqual(focusRow.value as? String, "25 min")

        focusRow.tap()
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "25")
        XCTAssertTrue(app.buttons["Set focus time"].isHittable)
        capture(app, name: "Focus time sheet")
        app.buttons["15 min"].tap()
        app.buttons["Set focus time"].tap()
        XCTAssertEqual(focusRow.value as? String, "15 min")

        app.buttons["Catnap break"].tap()
        app.buttons["No break"].tap()
        XCTAssertTrue(app.buttons["Set break time"].isHittable)
        capture(app, name: "Catnap break sheet")
        app.buttons["Set break time"].tap()
        XCTAssertEqual(app.buttons["Catnap break"].value as? String, "No break")

        app.buttons["Sessions"].tap()
        app.buttons["More sessions"].tap()
        capture(app, name: "Sessions sheet")
        app.buttons["Set sessions"].tap()
        XCTAssertEqual(app.buttons["Sessions"].value as? String, "5")
        XCTAssertTrue(app.staticTexts["About 1 hr 15 min of focus time."].exists)

        app.buttons["Sessions"].tap()
        app.buttons["Fewer sessions"].tap()
        let grabber = app.buttons["Sheet Grabber"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grabber.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons["Set sessions"])
        waitForExpectations(timeout: 5)
        XCTAssertTrue(focusRow.isHittable)
        XCTAssertEqual(app.buttons["Sessions"].value as? String, "5")

        app.tabBars.buttons["Presets"].tap()
        app.navigationBars.buttons["Add"].tap()
        app.buttons["Focus time"].tap()
        app.buttons["50 min"].tap()
        app.buttons["Set focus time"].tap()
        XCTAssertEqual(app.buttons["Focus time"].value as? String, "50 min")
        app.buttons["Sessions"].tap()
        XCTAssertTrue(app.buttons["Set sessions"].exists)
        app.buttons["Close"].tap()
    }

    @MainActor
    func test_activeTimerPauseResumeAndExitRestoreRoutine() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Start focusing"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["FOCUS SESSION"].exists)
        XCTAssertTrue(app.staticTexts["1 of 4"].exists)
        XCTAssertFalse(app.tabBars.buttons["Presets"].isHittable)
        capture(app, name: "Active focus")
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        let pausedTime = app.staticTexts["TimerCountdown"].value as? String
        capture(app, name: "Paused focus")
        XCTAssertEqual(app.staticTexts["TimerCountdown"].value as? String, pausedTime)
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["FOCUS SESSION"].exists)
        capture(app, name: "Focus after app return")
        app.buttons["End session"].tap()
        XCTAssertTrue(app.buttons["Start focusing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Presets"].isHittable)
        XCTAssertEqual(app.buttons["Focus time"].value as? String, "25 min")
    }

    @MainActor
    func test_activeTimerBreakCompletionRepeatAndBack() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Focus time"].tap()
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "0")
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "5")
        app.buttons["Set focus time"].tap()
        app.buttons["Catnap break"].tap()
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "0")
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "5")
        app.buttons["Set break time"].tap()
        app.buttons["Sessions"].tap()
        app.buttons["Fewer sessions"].tap()
        app.buttons["Fewer sessions"].tap()
        app.buttons["Set sessions"].tap()
        app.buttons["Start focusing"].tap()
        XCTAssertTrue(app.staticTexts["CATNAP BREAK"].waitForExistence(timeout: 10))
        capture(app, name: "Active break")
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        capture(app, name: "Paused break")
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Focus again"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["2 sessions completed"].exists)
        capture(app, name: "Routine complete")
        app.buttons["Focus again"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 of 2"].exists)
        XCTAssertTrue(app.staticTexts["FOCUS SESSION"].exists)
        XCTAssertTrue(app.buttons["Focus again"].waitForExistence(timeout: 20))
        app.buttons["Back to routine"].tap()
        XCTAssertTrue(app.buttons["Start focusing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Presets"].isHittable)
        XCTAssertEqual(app.buttons["Sessions"].value as? String, "2")
    }

    @MainActor
    private func setDuration(_ app: XCUIApplication, seconds: Int) {
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "0")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "0")
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "\(seconds)")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
