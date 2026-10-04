//
//  SwiftRadioUITests.swift
//  SwiftRadioUITests
//
//  Created by Jonah Stiennon on 12/3/15.
//  Copyright © 2015 matthewfecher.com. All rights reserved.
//

import XCTest

/// Exercises the real SwiftUI shell and the streaming adapter on the iOS 27 simulator.
@MainActor final class SwiftRadioUITests: XCTestCase {

    /// Cheap smoke test for CI: the bundled catalog renders under a large title and nothing plays yet.
    func testStationsListRenders() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let station = app.staticTexts["Absolute Country Hits"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 30))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 6)

        let navigationBar = app.navigationBars["Swift Radio"]
        XCTAssertTrue(navigationBar.exists)
        // A large title is laid out below the bar buttons, so it is taller than a compact one.
        let title = navigationBar.staticTexts["Swift Radio"].firstMatch
        XCTAssertTrue(title.exists)
        XCTAssertGreaterThan(title.frame.height, 30)

        XCTAssertFalse(app.otherElements["popupBar"].exists, "The bar appears only after a selection")
        capture("stations-list", app: app)
    }

    /// Full shell flow: select a station, open the popup, close it, then pull to refresh.
    func testPopupNavigationAndRefresh() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let station = app.staticTexts["Absolute Country Hits"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 30))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 6)
        XCTAssertTrue(app.navigationBars["Swift Radio"].exists)
        XCTAssertFalse(app.buttons["playbackToggle"].exists)
        capture("list", app: app)

        // Selecting a station raises the popup bar and starts the live stream.
        station.tap()
        let toggle = app.buttons["playbackToggle"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 30))
        let playingLive = NSPredicate(format: "label == %@", "Stop")
        expectation(for: playingLive, evaluatedWith: toggle)
        waitForExpectations(timeout: 60)
        capture("popup-bar", app: app)

        // Open the popup from the bar's leading half, clear of the transport button.
        let bar = app.otherElements["popupBar"].firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10))
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)).tap()
        // The adaptive player exposes a ScrollView; don't couple the contract to XCUI's
        // element classification of the container (the old fixed ZStack was an Other).
        let content = app.descendants(matching: .any)["nowPlayingContent"].firstMatch
        XCTAssertTrue(content.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["playerTransport"].isHittable)
        capture("popup-open", app: app)

        // Drag the artwork down past the dismissal threshold to close the popup.
        content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            .press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        XCTAssertTrue(app.navigationBars["Swift Radio"].waitForExistence(timeout: 10))
        XCTAssertTrue(station.waitForExistence(timeout: 10))
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Closing the popup restores the bar")
        capture("popup-closed", app: app)

        // Pull to refresh reloads the catalog without tearing down the popup bar.
        app.collectionViews.firstMatch.swipeDown(velocity: .slow)
        XCTAssertTrue(station.waitForExistence(timeout: 15))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 6)
        XCTAssertTrue(toggle.exists, "Refresh must keep the popup/navigation shell mounted")
        capture("after-refresh", app: app)
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Real UI + deterministic engine: transitions are independent of stream availability.
    func testStopResumeMarqueeAndReopen() throws {
        continueAfterFailure = false
        let app = fixtureApp()
        app.staticTexts["Absolute Country Hits"].firstMatch.tap()
        let toggle = app.buttons["playbackToggle"].firstMatch
        assertLabel("Stop", on: toggle)
        let indicator = app.buttons["showNowPlaying"].firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))
        assertMoves(indicator, "The toolbar equalizer animates while playing")
        capture("live-playing-indicators", app: app)
        toggle.tap()
        assertLabel("Play", on: toggle)
        assertGone(indicator, "The equalizer leaves the toolbar when playback stops")
        capture("live-stopped-indicators", app: app)
        toggle.tap()
        assertLabel("Stop", on: toggle)
        openPopup(app)
        let title = app.staticTexts["nowPlayingTitle"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        // The fixture title is longer than the screen, so a working marquee must move.
        XCTAssertTrue(title.label.contains("deliberately long"))
        assertMoves(title, "The long title scrolls")
        app.buttons["playerTransport"].tap()
        assertLabel("Play", on: app.buttons["playerTransport"])
        closePopup(app)
        assertGone(indicator, "No equalizer while stopped")
        openPopup(app)
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        assertMoves(title, "The marquee restarts when the popup reopens")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        assertMoves(title, "The marquee restarts after returning to the foreground")
        capture("marquee-foreground", app: app)
    }

    func testFilePauseSeekAndShareReturnToPlayer() throws {
        continueAfterFailure = false
        executionTimeAllowance = 180
        let app = fixtureApp()
        let station = app.staticTexts["MP3 file sample"].firstMatch
        if !station.isHittable { app.collectionViews.firstMatch.swipeUp() }
        station.tap()
        let toggle = app.buttons["playbackToggle"].firstMatch
        // A cold CI simulator can spend over 25 seconds compiling its first graphics pipeline
        // on the main thread. Allow that one-time setup before exercising transport transitions.
        assertLabel("Pause", on: toggle, timeout: 60)
        toggle.tap()
        assertLabel("Play", on: toggle)
        assertGone(app.buttons["showNowPlaying"].firstMatch, "The equalizer leaves the toolbar when paused")
        capture("file-paused-indicators", app: app)
        openPopup(app)
        let slider = app.sliders["playbackSeek"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        slider.adjust(toNormalizedSliderPosition: 0.5)
        assertLabel("Pause", on: app.buttons["playerTransport"])
        let elapsed = app.staticTexts["playbackElapsed"].label.split(separator: ":").compactMap { Int($0) }
        XCTAssertEqual(elapsed.count, 2)
        let seconds = elapsed.count == 2 ? elapsed[0] * 60 + elapsed[1] : -1
        // XCUI's normalized drag is approximate; exact engine seek values are core-tested.
        XCTAssertGreaterThanOrEqual(seconds, 75)
        XCTAssertLessThanOrEqual(seconds, 105)
        capture("file-seek-completed", app: app)
        // Repeat cancellation: the second presentation must not reuse stale sheet state.
        for iteration in 1...2 {
            app.buttons["playerOptions"].tap()
            let share = app.buttons["Share Now Playing"].firstMatch
            XCTAssertTrue(share.waitForExistence(timeout: 10))
            share.tap()
            let activity = app.otherElements["ActivityListView"].firstMatch
            XCTAssertTrue(activity.waitForExistence(timeout: 10))
            let close = try shareSheetCloseButton(app)
            capture("share-presented-\(iteration)", app: app)
            close.tap()
            assertGone(activity, "Cancelling Share dismisses the activity sheet")
            // The share sheet's dismissal animation keeps the player covered for a moment after the
            // button already exists; wait for it to become hittable rather than asserting at once.
            let options = app.buttons["playerOptions"].firstMatch
            let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: options)
            XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 10), .completed, "Options button is back after cancel")
            XCTAssertFalse(app.buttons["Share Now Playing"].exists, "Cancel returns to player, not Options")
            capture("share-returned-\(iteration)", app: app)
        }
    }

    func testLibraryLinkFeedbackAndReturn() throws {
        continueAfterFailure = false
        let app = fixtureApp()
        app.buttons["About Swift Radio"].firstMatch.tap()
        let libraries = app.buttons["Open Source Libraries"].firstMatch
        for _ in 0..<3 {
            if libraries.isHittable { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(libraries.isHittable)
        libraries.tap()
        let library = app.buttons.containing(.staticText, identifier: "FRadioPlayer").firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        capture("library-disclosures", app: app)
        library.tap()
        let done = app.buttons.matching(NSPredicate(format: "label IN %@", ["Done", "Close"])).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 15))
        capture("library-safari", app: app)
        done.tap()
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        XCTAssertTrue(library.isHittable)
    }

    private func fixtureApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-playback"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Absolute Country Hits"].firstMatch.waitForExistence(timeout: 30))
        return app
    }

    func testReselectionPreviousNextAndWebsiteHandoff() throws {
        continueAfterFailure = false
        let app = fixtureApp()
        let station = app.staticTexts["Absolute Country Hits"].firstMatch
        // A held row dragged into scrolling must cancel, not start a station.
        station.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.3,
                      thenDragTo: app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
        // The fixture starts playback about 0.7 s after a selection, so wait past that.
        assertStaysAbsent(app.buttons["playbackToggle"].firstMatch, for: 1.5)
        app.collectionViews.firstMatch.swipeDown()
        XCTAssertTrue(station.isHittable)
        station.tap()
        let toggle = app.buttons["playbackToggle"].firstMatch
        assertLabel("Stop", on: toggle)
        toggle.tap()
        assertLabel("Play", on: toggle)
        station.tap() // Selecting the stopped current row resumes, without opening the popup.
        assertLabel("Stop", on: toggle)
        XCTAssertFalse(app.buttons["playerTransport"].exists)
        station.tap() // Selecting the playing current row opens the popup.
        let transport = app.buttons["playerTransport"]
        XCTAssertTrue(transport.waitForExistence(timeout: 10))
        app.buttons["Previous station"].tap() // First wraps to the file sample.
        assertLabel("Pause", on: transport)
        XCTAssertTrue(app.sliders["playbackSeek"].waitForExistence(timeout: 5))
        capture("previous-wraps-to-file", app: app)
        app.buttons["Next station"].tap()
        assertLabel("Stop", on: transport)
        assertGone(app.sliders["playbackSeek"].firstMatch, "Live streams have no scrubber")
        capture("next-wraps-to-live", app: app)
        app.buttons["playerOptions"].tap()
        let website = app.buttons["Station Website"].firstMatch
        XCTAssertTrue(website.waitForExistence(timeout: 10))
        website.tap()
        let close = app.buttons.matching(NSPredicate(format: "label IN %@", ["Done", "Close"])).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 15))
        capture("options-website-handoff", app: app)
        close.tap()
        XCTAssertTrue(app.navigationBars["Swift Radio"].waitForExistence(timeout: 10))
        XCTAssertTrue(toggle.isHittable)
        assertGone(transport, "Closing the website returns to the list, not the player")
    }

    /// Motion is asserted by comparing element screenshots over time. Polling instead of one fixed
    /// delay keeps the test fast when the animation is running and bounded when it is not.
    private func assertMoves(_ element: XCUIElement, _ message: String, within timeout: TimeInterval = 5,
                             file: StaticString = #filePath, line: UInt = #line) {
        // Let presentation transitions and artwork crossfades finish so they are not read as motion.
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
        let first = element.screenshot().pngRepresentation
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            if element.screenshot().pngRepresentation != first { return }
        }
        XCTFail(message, file: file, line: line)
    }

    /// Waits for removal instead of checking right after a state change, which races the toolbar
    /// and popup transitions.
    private func assertGone(_ element: XCUIElement, _ message: String,
                            file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed, message, file: file, line: line)
    }

    private func assertStaysAbsent(_ element: XCUIElement, for duration: TimeInterval,
                                   file: StaticString = #filePath, line: UInt = #line) {
        let appears = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [appears], timeout: duration), .timedOut, file: file, line: line)
    }

    /// The activity container can exist before its remote content finishes rendering on CI.
    /// Never mistake the popup's covered Close button for a ready share-sheet control.
    private func shareSheetCloseButton(_ app: XCUIApplication,
                                       file: StaticString = #filePath, line: UInt = #line) throws -> XCUIElement {
        // The share controls live in a remote process. Binding a mixed app/remote query by index
        // can count both Close buttons, then resolve index 1 against just the remote match.
        let close = app.buttons["header.closeButton"].firstMatch
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND isHittable == true"), object: close)
        if XCTWaiter.wait(for: [ready], timeout: 60) == .completed { return close }
        capture("share-close-unavailable", app: app)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "share-close-unavailable-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        return try XCTUnwrap(nil as XCUIElement?, "Share must render a hittable close control before cancellation",
                             file: file, line: line)
    }

    private func assertLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval = 15,
                             file: StaticString = #filePath, line: UInt = #line) {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: timeout), .completed, file: file, line: line)
    }

    private func openPopup(_ app: XCUIApplication) {
        let bar = app.otherElements["popupBar"].firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10))
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["playerTransport"].waitForExistence(timeout: 10))
    }

    private func closePopup(_ app: XCUIApplication) {
        let content = app.descendants(matching: .any)["nowPlayingContent"].firstMatch
        content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            .press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        XCTAssertTrue(app.navigationBars["Swift Radio"].waitForExistence(timeout: 10))
    }

    /// Layout/navigation do not need a remote stream to become ready. Keep this regression
    /// separate from the live-playback integration test so a station outage cannot mask it.
    func testPlayerControlsFitAndOptionsNavigate() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let station = app.staticTexts["MP3 file sample"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 30))
        if !station.isHittable { app.collectionViews.firstMatch.swipeUp() }
        station.tap()
        let indicator = app.buttons["showNowPlaying"]
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["popupBar"].firstMatch.waitForExistence(timeout: 10))
        capture("popup-bar-collapsed", app: app)
        indicator.tap()
        let transport = app.buttons["playerTransport"]
        let options = app.buttons["playerOptions"]
        XCTAssertTrue(transport.waitForExistence(timeout: 10))
        XCTAssertTrue(transport.isHittable)
        XCTAssertTrue(options.isHittable, "Options must not overflow the popup's screen bounds")
        XCTAssertTrue(app.frame.contains(transport.frame))
        XCTAssertTrue(app.frame.contains(options.frame))
        capture("player-controls-visible", app: app)
        options.tap()
        let info = app.buttons["About Station"].firstMatch
        XCTAssertTrue(info.waitForExistence(timeout: 10))
        // The sheet's height is measured from its content; the capture shows whether it clips or gaps.
        let share = app.buttons["Share Now Playing"].firstMatch
        let sheetSettled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: info)
        let shareVisible = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: share)
        XCTAssertEqual(XCTWaiter.wait(for: [sheetSettled, shareVisible], timeout: 10), .completed)
        XCTAssertTrue(app.frame.contains(share.frame), "The last option must not be clipped")
        capture("options-sheet", app: app)
        info.tap()
        XCTAssertTrue(app.navigationBars["About Station"].waitForExistence(timeout: 10),
                      "The station push must run after options and popup have dismissed")
        let website = app.buttons["stationWebsite"].firstMatch
        XCTAssertTrue(website.waitForExistence(timeout: 10))
        let websiteIsReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: website)
        XCTAssertEqual(XCTWaiter.wait(for: [websiteIsReady], timeout: 10), .completed)
        capture("station-info-from-options", app: app)
    }

    func testAboutFeaturesNavigationAndDismissal() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let about = app.buttons["About Swift Radio"].firstMatch
        XCTAssertTrue(about.waitForExistence(timeout: 30))
        about.tap()
        let introduction = app.staticTexts["aboutIntroduction"]
        XCTAssertTrue(introduction.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.contains(introduction.frame))
        capture("about-introduction", app: app)
        app.buttons["Features"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Features"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Swift Codebase"].exists)
        capture("about-features", app: app)
        app.navigationBars["Features"].buttons.firstMatch.tap()
        let list = app.collectionViews.firstMatch
        let logo = app.images["aboutFooterLogo"]
        for _ in 0..<4 {
            if logo.isHittable { break }
            list.swipeUp()
        }
        XCTAssertTrue(logo.isHittable)
        let versionRow = list.cells.containing(.staticText, identifier: "App Version").firstMatch
        XCTAssertTrue(versionRow.exists)
        let footerGap = logo.frame.minY - versionRow.frame.maxY
        XCTAssertGreaterThanOrEqual(footerGap, 16)
        XCTAssertLessThanOrEqual(footerGap, 56, "Do not double up grouped-section and footer padding")
        capture("about-footer-spacing", app: app)
        let close = app.buttons["Close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        close.tap()
        XCTAssertTrue(app.navigationBars["Swift Radio"].waitForExistence(timeout: 10))
    }
}
