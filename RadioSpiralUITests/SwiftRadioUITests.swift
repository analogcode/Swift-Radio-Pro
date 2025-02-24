//
//  SwiftRadioUITests.swift
//  SwiftRadioUITests
//
//  Created by Jonah Stiennon on 12/3/15.
//  Copyright © 2015 matthewfecher.com. All rights reserved.
//

import XCTest

class SwiftRadioUITests: XCTestCase {
    
    let app = XCUIApplication()
    let stations = XCUIApplication().cells
    let hamburgerMenu = XCUIApplication().navigationBars["Swift Radio"].buttons["icon-hamburger"]
    let pauseButton = XCUIApplication().buttons["btn play"]
    let playButton = XCUIApplication().buttons["btn play"]
    let stopButton = XCUIApplication().buttons["btn stop"]
    let shareButton = XCUIApplication().buttons["share"]
    let volume = XCUIApplication().sliders.element(boundBy: 0)
    
    @MainActor override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
   /*
    @MainActor func testHamburgerMenu() {
        
        let app = XCUIApplication()
        app.navigationBars["RadioSpiral streams"].buttons["icon hamburger"].tap()
        app.buttons["About"].tap()
        snapshot("About")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        app/*@START_MENU_TOKEN@*/.staticTexts["Visit our website"]/*[[".buttons[\"Visit our website\"].staticTexts[\"Visit our website\"]",".staticTexts[\"Visit our website\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        _ = safari.wait(for: .runningForeground, timeout: 30)
        app.activate()
        app.buttons["OK"].tap()
        print(app.buttons.keys)
        app.buttons["btn close"].tap()
    }
    */
    @MainActor func testTransitionToNowPlaying() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        self.expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: pauseButton, handler: nil)
        self.waitForExpectations(timeout: 30.0, handler: nil)
        snapshot("playing")
    }
    
    @MainActor func testSharing() {
        self.expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: shareButton, handler: nil)
        self.waitForExpectations(timeout: 10.0, handler: nil)
        app.buttons["share"].tap()
        self.expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: shareButton, handler: nil)
        self.waitForExpectations(timeout: 10.0, handler: nil)
        snapshot("share")
       
    }
}

