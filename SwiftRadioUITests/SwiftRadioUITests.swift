//
//  SwiftRadioUITests.swift
//  SwiftRadioUITests
//
//  Created by Jonah Stiennon on 12/3/15.
//  Copyright © 2015 CodeMarket.io. All rights reserved.
//

import XCTest

class SwiftRadioUITests: XCTestCase {
    
    let app = XCUIApplication()
    let stations = XCUIApplication().cells
    let hamburgerMenu = XCUIApplication().navigationBars["Swift Radio"].buttons["icon hamburger"]
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // wait for the main view to load
        self.expectationForPredicate(
            NSPredicate(format: "self.count > 0"),
            evaluatedWithObject: stations,
            handler: nil)
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func assertStationsPresent() {
        let numStations:UInt = 4
        XCTAssertEqual(stations.count, numStations)
        
        let texts = stations.staticTexts.count
        XCTAssertEqual(texts, numStations * 2)
    }
    
    func assertHamburgerContent() {
        XCTAssertNotNil(app.staticTexts["Created by: Matthew Fecher"])
    }
    
    func testMainStationsView() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        assertStationsPresent()
        
        hamburgerMenu.tap()
        app.buttons["About"].tap()
        assertHamburgerContent()
        app.buttons["Okay"].tap()
        app.buttons["btn close"].tap()
        
        assertStationsPresent()
        
    }
    
}
