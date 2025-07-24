//
//  myBiographyUITests.swift
//  myBiographyUITests
//
//  Created by zhangqiao on 2025/7/16.
//

import XCTest

final class myBiographyUITests: XCTestCase {

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
    func testRecordButtonToggle() throws {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["Start Recording"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 1))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
