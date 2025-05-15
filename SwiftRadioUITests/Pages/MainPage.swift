//
//  MainPage.swift
//  SwiftRadio
//
//  Created by mihail on 06.05.2025.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//
import XCTest

final class MainPage: CommonPage {

//  MainPage
    private var cells: XCUIElement {
        app.cells.element(boundBy: 0)
        
    }
    
    private var nowPlayingBottomButton: XCUIElement {
        app.buttons["nowPlayingBottomButton"]
    }
    
    
    private var nowPlayingTitleLabel: XCUIElement {
        app.staticTexts["nowPlayingTitleLabel"]
    }
    
    private var nowPlayingSubtitleLabel: XCUIElement {
        app.staticTexts["nowPlayingSubtitleLabel"]
    }

//  MenuView
    private var menuViewCloseBtn: XCUIElement {
        app.buttons["menuViewCloseBtn"]
    }
    
    private var menuViewRadioLogo: XCUIElement {
        app.images["menuViewRadioLogo"]
    }
    
    private var menuViewAboutBtn: XCUIElement {
        app.buttons["menuViewAboutBtn"]
    }
    
    private var menuWebsiteBtn: XCUIElement {
        app.buttons["menuWebsiteBtn"]
    }
    
    private var menuViewNames: XCUIElement {
        app.staticTexts["menuViewNames"]
    }

//  NowPlayingView
    private var albumImageView: XCUIElement {
        app.images["albumImageView"]
    }
    
    private var stationsDescriptionLabel: XCUIElement {
        app.staticTexts["stationsDescriptionLabel"]
    }
    
    private var previousButton: XCUIElement {
        app.buttons["previousButton"]
    }
    
    private var playingButton: XCUIElement {
        app.buttons["playingButton"]
    }
    
    private var stopButton: XCUIElement {
        app.buttons["stopButton"]
    }
    
    private var nextButton: XCUIElement {
        app.buttons["nextButton"]
    }
    
    private var mpVolumeSlider: XCUIElement {
        app.sliders["mpVolumeSlider"]
    }
    
    private var songLabel: XCUIElement {
        app.staticTexts["songLabel"]
    }
    
    private var artistLabel: XCUIElement {
        app.staticTexts["artistLabel"]
    }
    
    private var nowPlayingRadioLogo: XCUIElement {
        app.images["nowPlayingRadioLogo"]
    }
    
    private var airPlayButton: XCUIElement {
        app.buttons["airPlayButton"]
    }
    
    private var shareStationBtn: XCUIElement {
        app.buttons["shareStationBtn"]
    }
    
    private var moreInfoBtn: XCUIElement {
        app.buttons["moreInfoBtn"]
    }
    
//  InfoDetailView
    private var stationImageView: XCUIElement {
        app.images["stationImageView"]
    }
    
    private var stationNameLabel: XCUIElement {
        app.staticTexts["stationNameLabel"]
    }
    
    private var stationDescriptionLabel: XCUIElement {
        app.staticTexts["stationDescriptionLabel"]
    }
    
    private var okayButton: XCUIElement {
        app.buttons["okayButton"]
    }
    
//  AboutView
    private var aboutAppViewRadioLogo: XCUIElement {
        app.images["aboutAppViewRadioLogo"]
    }
    
    private var aboutAppViewLabel: XCUIElement {
        app.staticTexts["aboutAppViewLabel"]
    }
    
    private var aboutAppViewVersionLabel: XCUIElement {
        app.staticTexts["aboutAppViewVersionLabel"]
    }
    
    private var aboutAppViewWebsiteBtn: XCUIElement {
        app.buttons["aboutViewWebsiteBtn"]
    }
    
    private var aboutAppViewEmailMeBtn: XCUIElement {
        app.buttons["aboutViewEmailMeBtn"]
    }
    
    private var aboutAppViewOkayBtn: XCUIElement {
        app.buttons["aboutAppViewOkayBtn"]
    }
}
