//
//  SwiftRadioUITests.swift
//  SwiftRadioUITests
//
//  Created by Jonah Stiennon on 12/3/15.
//  Copyright © 2015 matthewfecher.com. All rights reserved.
//

import XCTest
import SwiftRadio

class SwiftRadioUITests: XCTestCase {
    
    typealias popupId = AccessIDs.PopupInfoView
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        XCUIApplication().launch()
    }
    
    // MARK: - TearDown
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Methods
    func tapElement(withIdentifier identifier: String) {
        let app = XCUIApplication()
        let button = app.buttons[identifier]
        
        if button.exists {
            button.tap()
        } else {
            XCTFail("Button with identifier \(identifier) does not exist.")
        }
    }
    
    func tapElement(withIndex index: Int) {
        let app = XCUIApplication()
        let index = app.buttons.element(boundBy: index)
        
        if index.exists {
            index.tap()
        } else {
            XCTFail("Button with index \(index) does not exist")
        }
    }
    
    func tapAt(coordinates x: Double, y: Double) {
        let app = XCUIApplication()
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        
        coordinate.tap()
    }
    
    func tapElement(withPredicate predicate: NSPredicate, timeout: TimeInterval = 3) {
        let app = XCUIApplication()
        let element = app.descendants(matching: .any).element(matching: predicate)
        
        let exist = element.waitForExistence(timeout: timeout)
        if exist {
            element.tap()
        } else {
            XCTFail("Element with predicate \(predicate) does not exist.")
        }
    }
    
    func closePopup() {
        let app = XCUIApplication()
        let closeButton = app.buttons["popupCloseButton"]
        
        if closeButton.exists {
            closeButton.tap()
        } else {
            XCTFail("Popup button \(closeButton) does not exist.")
        }
    }
    
    func pressBackOrBurgetNavBar() {
        let app = XCUIApplication()
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        
        if backButton.exists {
            backButton.tap()
        } else {
            XCTFail("Button \(backButton) does not exist.")
        }
    }

    
    // MARK: - Tests
    func testTapElement() {
    }
    
    
}

extension XCUIElement {
    func assertIsSelected() {
        XCTAssertTrue(self.isSelected, "Expected element \(self) is selected")
    }
    
    func assertIsNotSelected() {
        XCTAssertFalse(self.isSelected, "Expected element \(self) is not selected")
    }
    
    func assertIsVisisble() {
        XCTAssertTrue(self.exists, "Expected element \(self) is visible")
    }
    
    func assertIsNotVisible() {
        XCTAssertFalse(self.exists, "Expected element \(self) is not visible")
    }
}
