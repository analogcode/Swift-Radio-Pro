//
//  baseTest.swift
//  SwiftRadio
//
//  Created by mihail on 06.05.2025.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//
import XCTest

class BaseTest: XCTestCase {
    let app = XCUIApplication()
            
        override func setUp() {
            super.setUp()
            
            continueAfterFailure = false // хард ассерты. По дефолту используются софт
            app.launch()
        }
}


