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
