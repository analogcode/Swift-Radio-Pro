//
//  SmokeTest.swift
//  SwiftRadio
//
//  Created by mihail on 06.05.2025.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import XCTest

class SmokeTest: BaseTest {
    
    // Bottom bar плеер становится активным после запуска радио станции
    func testNowPlayingBottomBarIsEnabled() {
        let nowPlayingBottomButton = app.buttons["nowPlayingBottomButton"]
        XCTAssertFalse(nowPlayingBottomButton.isEnabled)
        
        let cell = app.cells.element(boundBy: 0)
        cell.tap()
        
        let backButton = app.navigationBars.buttons["Back"]
        backButton.tap()
        
        XCTAssertTrue(nowPlayingBottomButton.isEnabled)
    }
    
    // Label 'Название песни' меняется на 'Station Paused...' после нажатия на Паузу
    func testStationPausedLabel() {
        let cell = app.cells.element(boundBy: 0)
        cell.tap()
        
        let songLabel = app.staticTexts["songLabel"]
        let playingButton = app.buttons["playingButton"]
        
        playingButton.tap()
        XCTAssertTrue(songLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(songLabel.label, "Station Paused...")
    }
    
    // Burger menu открывается, кнопка About появляется в окне, закрыть окно
    func testOpencCloseBurgerMenuView() {
        let burgerButton = app.navigationBars.buttons["icon hamburger"]
        let closeButton = app.buttons["menuViewCloseBtn"]
        let aboutButton = app.buttons["menuViewAboutBtn"]
        
        burgerButton.tap()
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 3))
        closeButton.tap()
    }
    
    // More Info окно открывается, Имя станции отображается, закрыть окно
    func testOpenCloseInfoView() {
        let cell = app.cells.element(boundBy: 0)
        let artist = app.staticTexts["artistLabel"]
        XCTAssertTrue(cell.waitForExistence(timeout: 3))
        cell.tap()
        XCTAssertTrue(artist.waitForExistence(timeout: 3))
        
        let moreInfo = app.buttons["moreInfoBtn"]
        moreInfo.tap()
        
        let moreInfoStationName = app.staticTexts["stationNameLabel"]
        XCTAssertTrue(moreInfoStationName.waitForExistence(timeout: 1))
                      
        let infoViewOkayButton = app.buttons["okayButton"]
        infoViewOkayButton.tap()
        
        XCTAssertTrue(artist.waitForExistence(timeout: 3))
        
    }
    
    // About App окно открывается, Лого приложения отображается, закрыть окно
    func testOpenCloseAboutView() {
        let cell = app.cells.element(boundBy: 0)
        let artist = app.staticTexts["artistLabel"]
        XCTAssertTrue(cell.waitForExistence(timeout: 3))
        cell.tap()
        XCTAssertTrue(artist.waitForExistence(timeout: 3))
        
        let radioLogo = app.buttons["nowPlayingRadioLogo"]
        radioLogo.tap()
        
        let radioLogoImage = app.images["aboutAppViewRadioLogo"]
        XCTAssertTrue(radioLogoImage.waitForExistence(timeout: 3))
        
        let aboutViewOkayButton = app.buttons["aboutAppViewOkayBtn"]
        aboutViewOkayButton.tap()
        
        XCTAssertTrue(artist.waitForExistence(timeout: 3))
        
    }
}
