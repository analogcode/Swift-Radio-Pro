//
//  CommonPage.swift
//  SwiftRadio
//
//  Created by mihail on 06.05.2025.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import XCTest

class CommonPage: XCTest {
    required init(app: XCUIApplication) {
            self.app = app
        }
        
    let app: XCUIApplication
    private var logInText: XCUIElement {
    app.navigationBars.buttons.element(boundBy: 0)
    
        }
}
