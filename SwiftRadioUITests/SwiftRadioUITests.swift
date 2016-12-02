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
    let hamburgerMenu = XCUIApplication().navigationBars["Swift Radio"].buttons["icon hamburger"]
    let pauseButton = XCUIApplication().buttons["btn pause"]
    let playButton = XCUIApplication().buttons["btn play"]
    let volume = XCUIApplication().sliders.element(boundBy: 0)
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // wait for the main view to load
        self.expectation(
            for: NSPredicate(format: "self.count > 0"),
            evaluatedWith: stations,
            handler: nil)
        self.waitForExpectations(timeout: 10.0, handler: nil)
        
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
        XCTAssertTrue(app.staticTexts["Created by: Matthew Fecher"].exists)
    }
    
    func assertAboutContent() {
        XCTAssertTrue(app.buttons["email me"].exists)
        XCTAssertTrue(app.buttons["matthewfecher.com"].exists)
    }
    
    func assertPaused() {
        XCTAssertFalse(pauseButton.isEnabled)
        XCTAssertTrue(playButton.isEnabled)
        XCTAssertTrue(app.staticTexts["Station Paused..."].exists);
    }
    
    func assertPlaying() {
        XCTAssertTrue(pauseButton.isEnabled)
        XCTAssertFalse(playButton.isEnabled)
        XCTAssertFalse(app.staticTexts["Station Paused..."].exists);
    }
    
    func assertStationOnMenu(_ stationName:String) {
        let button = app.buttons["nowPlaying"];
        if let value:String = button.label {
            XCTAssertTrue(value.contains(stationName))
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func assertStationInfo() {
        let textView = app.textViews.element(boundBy: 0)
        if let value = textView.value {
            XCTAssertGreaterThan((value as AnyObject).length, 10)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func waitForStationToLoad() {
        self.expectation(
            for: NSPredicate(format: "exists == 0"),
            evaluatedWith: app.staticTexts["Loading Station..."],
            handler: nil)
        self.waitForExpectations(timeout: 25.0, handler: nil)

    }
    
    func testMainStationsView() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        assertStationsPresent()
        
        hamburgerMenu.tap()
        assertHamburgerContent()
        app.buttons["About"].tap()
        assertAboutContent()
        app.buttons["Okay"].tap()
        app.buttons["btn close"].tap()
        assertStationsPresent()
        
        let firstStation = stations.element(boundBy: 0)
        let stationName:String = firstStation.children(matching: .staticText).element(boundBy: 0).label
        assertStationOnMenu("Choose")
        firstStation.tap()
        waitForStationToLoad();
        
        pauseButton.tap()
        assertPaused()
        playButton.tap()
        assertPlaying()
        app.navigationBars["Sub Pop Radio"].buttons["Back"].tap()
        assertStationOnMenu(stationName)
        app.navigationBars["Swift Radio"].buttons["btn nowPlaying"].tap()
        waitForStationToLoad()
        volume.adjust(toNormalizedSliderPosition: 0.2)
        volume.adjust(toNormalizedSliderPosition: 0.8)
        volume.adjust(toNormalizedSliderPosition: 0.5)
        app.buttons["More Info"].tap()
        assertStationInfo()
        app.buttons["Okay"].tap()
        app.buttons["logo"].tap()
        assertAboutContent()
        app.buttons["Okay"].tap()
    }
    
}
