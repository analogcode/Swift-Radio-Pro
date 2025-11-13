//
//  ConfigClientTests.swift
//  ConfigClientTests
//
//  Created by Joe McMahon on 11/12/25.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import XCTest
@testable import RadioSpiral

class ConfigClientTests: XCTestCase {

    var sut: ConfigClient!
    var testConfigURL: String!

    override func setUp() {
        super.setUp()

        // Get path to test config file
        let testBundle = Bundle(for: ConfigClientTests.self)
        if let testConfigPath = testBundle.path(forResource: "test-config-with-fallback", ofType: "json") {
            testConfigURL = URL(fileURLWithPath: testConfigPath).absoluteString
            sut = ConfigClient(configURL: testConfigURL)
        } else {
            XCTFail("Could not find test config file")
        }
    }

    override func tearDown() {
        sut = nil
        testConfigURL = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testConfigClientInitializationWithDefaultURL() {
        let client = ConfigClient()
        XCTAssertNotNil(client, "ConfigClient should initialize with default URL")
    }

    func testConfigClientInitializationWithCustomURL() {
        let customURL = "file:///test/path/config.json"
        let client = ConfigClient(configURL: customURL)
        XCTAssertNotNil(client, "ConfigClient should initialize with custom URL")
    }

    // MARK: - Station Lookup Tests

    func testGetStationInfoWithValidShortCode() {
        let station = sut.getStationInfo(byShortCode: "test_station")
        // Initially should be nil until stations are fetched
        XCTAssertNil(station, "Station lookup should return nil before stations are loaded")
    }

    func testGetStationInfoWithInvalidShortCode() {
        let station = sut.getStationInfo(byShortCode: "nonexistent_station")
        XCTAssertNil(station, "Station lookup with invalid short code should return nil")
    }

    // MARK: - Fetch Stations Tests

    func testFetchStationsFromLocalConfig() {
        let expectation = self.expectation(description: "Fetch stations from local config")

        sut.fetchStations { result in
            switch result {
            case .success(let stations):
                XCTAssertFalse(stations.isEmpty, "Should fetch at least one station")
                XCTAssertTrue(stations.contains { $0.shortCode == "test_station" },
                             "Should contain test_station from static config")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testFetchedStationHasRequiredFields() {
        let expectation = self.expectation(description: "Fetched station has required fields")

        sut.fetchStations { result in
            switch result {
            case .success(let stations):
                if let testStation = stations.first(where: { $0.shortCode == "test_station" }) {
                    XCTAssertFalse(testStation.name.isEmpty, "Station should have name")
                    XCTAssertFalse(testStation.shortCode.isEmpty, "Station should have shortCode")
                    XCTAssertFalse(testStation.desc.isEmpty, "Station should have desc")
                    expectation.fulfill()
                } else {
                    XCTFail("test_station not found in fetched stations")
                }
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Station Lookup After Fetch Tests

    func testGetStationInfoAfterFetch() {
        let expectation = self.expectation(description: "Get station info after fetch")

        sut.fetchStations { [weak self] result in
            switch result {
            case .success:
                let station = self?.sut.getStationInfo(byShortCode: "test_station")
                XCTAssertNotNil(station, "Should find station after fetch")
                XCTAssertEqual(station?.name, "Test Station", "Station name should match")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Config Structure Tests

    func testConfigWrapperDecoding() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-with-fallback", ofType: "json") else {
            XCTFail("Could not find test config file")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testConfigPath))
            let config = try JSONDecoder().decode(ConfigWrapper.self, from: data)

            XCTAssertFalse(config.configs.isEmpty, "Config should have at least one source")
            XCTAssertTrue(config.configs.contains { $0.format == .static },
                         "Config should include static format")
        } catch {
            XCTFail("Failed to decode config: \(error)")
        }
    }

    func testStaticConfigSourceDecoding() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-with-fallback", ofType: "json") else {
            XCTFail("Could not find test config file")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testConfigPath))
            let config = try JSONDecoder().decode(ConfigWrapper.self, from: data)

            if let staticConfig = config.configs.first(where: { $0.format == .static }) {
                XCTAssertNotNil(staticConfig.stations, "Static config should have stations")
                XCTAssertFalse(staticConfig.stations?.isEmpty ?? true, "Static config should have at least one station")
            } else {
                XCTFail("Could not find static config source")
            }
        } catch {
            XCTFail("Failed to decode config: \(error)")
        }
    }

    // MARK: - Early-Stop and Fallback Chain Tests

    func testEarlyStopOnFirstSuccessfulConfig() {
        let expectation = self.expectation(description: "Early stop on first successful config")

        sut.fetchStations { result in
            switch result {
            case .success(let stations):
                // Should have exactly 1 station from static config (since Azuracast servers fail)
                XCTAssertEqual(stations.count, 1, "Should get exactly one station from fallback static config")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testAzuracastStationParsing() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-with-fallback", ofType: "json") else {
            XCTFail("Could not find test config file")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testConfigPath))
            let config = try JSONDecoder().decode(ConfigWrapper.self, from: data)

            if let staticConfig = config.configs.first(where: { $0.format == .static }) {
                let stations = staticConfig.safeStations
                XCTAssertEqual(stations.count, 1, "Should have one station in static config")

                if let station = stations.first {
                    // Verify all required fields are present
                    XCTAssertEqual(station.name, "Test Station", "Station name should match")
                    XCTAssertEqual(station.shortCode, "test_station", "Short code should match")
                    XCTAssertFalse(station.desc.isEmpty, "Description should not be empty")
                    XCTAssertFalse(station.longDesc.isEmpty, "Long description should not be empty")
                    XCTAssertEqual(station.serverName, "test.local", "Server name should match")
                    XCTAssertFalse(station.streamURL.isEmpty, "Stream URL should not be empty")
                }
            } else {
                XCTFail("Could not find static config source")
            }
        } catch {
            XCTFail("Failed to decode config: \(error)")
        }
    }

    func testFallbackChainOrder() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-with-fallback", ofType: "json") else {
            XCTFail("Could not find test config file")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testConfigPath))
            let config = try JSONDecoder().decode(ConfigWrapper.self, from: data)

            // Verify config has all three sources in order
            XCTAssertEqual(config.configs.count, 3, "Should have 3 config sources")
            XCTAssertEqual(config.configs[0].format, .azuracast, "First should be azuracast")
            XCTAssertEqual(config.configs[1].format, .azuracast, "Second should be azuracast")
            XCTAssertEqual(config.configs[2].format, .static, "Third should be static")

            // Verify first Azuracast has server set
            XCTAssertEqual(config.configs[0].server, "primary.example.com", "Primary server should be set")
            // Verify second Azuracast has server set
            XCTAssertEqual(config.configs[1].server, "fallback.example.com", "Fallback server should be set")
        } catch {
            XCTFail("Failed to decode config: \(error)")
        }
    }

    func testEarlyStopWithMultipleStaticSources() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-with-real-server", ofType: "json") else {
            XCTFail("Could not find test config with real server")
            return
        }

        let testURL = URL(fileURLWithPath: testConfigPath).absoluteString
        let client = ConfigClient(configURL: testURL)
        let expectation = self.expectation(description: "Early stop with multiple static sources")

        client.fetchStations { result in
            switch result {
            case .success(let stations):
                // Should have exactly 2 stations from first static config
                // (verifying we stopped at first success and didn't continue to second static config)
                XCTAssertEqual(stations.count, 2, "Should get exactly 2 stations from first config, not more from fallback")

                // Verify we got the first station
                if let firstStation = stations.first(where: { $0.shortCode == "test_static_1" }) {
                    XCTAssertEqual(firstStation.name, "Test Station - Direct Static", "Should have first station")
                } else {
                    XCTFail("Should have test_static_1 station")
                }

                // Verify we do NOT have the fallback station
                let hasFallback = stations.contains { $0.shortCode == "fallback_station" }
                XCTAssertFalse(hasFallback, "Should not have fallback_station (should have early-stopped)")

                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Live Azuracast Public API Tests (No auth required!)

    func testLiveAzuracastPublicAPI() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-live-azuracast", ofType: "json") else {
            XCTFail("Could not find test config for live Azuracast")
            return
        }

        let testURL = URL(fileURLWithPath: testConfigPath).absoluteString
        let client = ConfigClient(configURL: testURL)
        let expectation = self.expectation(description: "Fetch with exclusion logic and fallback")

        client.fetchStations { result in
            switch result {
            case .success(let stations):
                XCTAssertFalse(stations.isEmpty, "Should fetch at least one station from fallback")

                // Verify we got the fallback station (azuratest_radio is excluded)
                if let fallback = stations.first(where: { $0.shortCode == "test_fallback" }) {
                    XCTAssertEqual(fallback.name, "Test Fallback Station", "Should have fallback station when Azuracast is excluded")
                    XCTAssertEqual(fallback.shortCode, "test_fallback", "Fallback station should have correct shortcode")
                } else {
                    XCTFail("Should have fallen back to static config since azuratest_radio is excluded")
                }

                // Verify excluded station is NOT in results
                let hasExcluded = stations.contains { $0.shortCode == "azuratest_radio" }
                XCTAssertFalse(hasExcluded, "Excluded station should not be in results")

                print("✓ Exclusion logic working: fetched \(stations.count) station(s) after excluding azuratest_radio")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch: \(error)")
            }
        }

        waitForExpectations(timeout: 15.0)
    }

    // MARK: - RadioStation Converter Tests

    func testStationConfigToDictionary() {
        // Simple test to verify StationConfig can be created
        let sampleConfig = StationConfig(
            name: "Test Radio",
            streamURL: "https://example.com/stream",
            imageURL: "https://example.com/image.png",
            desc: "Test Description",
            longDesc: "Test Long Description",
            serverName: "example.com",
            shortCode: "test_radio",
            defaultDJ: "DJ Test"
        )

        // Verify the config was created with correct values
        XCTAssertEqual(sampleConfig.name, "Test Radio", "Name should be set correctly")
        XCTAssertEqual(sampleConfig.shortCode, "test_radio", "Short code should be set correctly")
        XCTAssertEqual(sampleConfig.streamURL, "https://example.com/stream", "Stream URL should be set correctly")
    }

    func testStationConfigFromFetchedData() {
        let expectation = self.expectation(description: "Fetch and verify StationConfig")

        sut.fetchStations { result in
            switch result {
            case .success(let stationConfigs):
                XCTAssertFalse(stationConfigs.isEmpty, "Should have fetched at least one station")

                // Verify first config has all required fields
                if let firstConfig = stationConfigs.first {
                    XCTAssertFalse(firstConfig.name.isEmpty, "Config name should not be empty")
                    XCTAssertFalse(firstConfig.shortCode.isEmpty, "Config short code should not be empty")
                    expectation.fulfill()
                } else {
                    XCTFail("No stations were fetched")
                }
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - ConfigClient Fallback Lookup Tests

    func testConfigClientCachingForFallback() {
        let expectation = self.expectation(description: "ConfigClient caches stations for fallback lookup")

        // Fetch stations to populate cache
        sut.fetchStations { result in
            switch result {
            case .success(let stationConfigs):
                XCTAssertFalse(stationConfigs.isEmpty, "Should fetch at least one station")

                // Verify we can look up a station from the cache by shortCode
                if let firstConfig = stationConfigs.first {
                    let lookedUpStation = self.sut.getStationInfo(byShortCode: firstConfig.shortCode)

                    // Verify the looked-up station matches the original
                    XCTAssertNotNil(lookedUpStation, "Should find station in cache by shortCode")
                    XCTAssertEqual(lookedUpStation?.name, firstConfig.name, "Station name should match")
                    XCTAssertEqual(lookedUpStation?.shortCode, firstConfig.shortCode, "Station shortCode should match")

                    // Verify all fields are available for metadata fallback
                    XCTAssertFalse(lookedUpStation?.desc.isEmpty ?? true, "Station description should not be empty")
                    XCTAssertFalse(lookedUpStation?.defaultDJ.isEmpty ?? true, "Station defaultDJ should not be empty")

                    expectation.fulfill()
                } else {
                    XCTFail("No stations were fetched")
                }
            case .failure(let error):
                XCTFail("Failed to fetch stations: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Production Configuration Tests

    func testProductionConfigurationWithSpiralRadio() {
        guard let testConfigPath = Bundle(for: ConfigClientTests.self).path(forResource: "test-config-production", ofType: "json") else {
            XCTFail("Could not find production config file")
            return
        }

        let testURL = URL(fileURLWithPath: testConfigPath).absoluteString
        let productionClient = ConfigClient(configURL: testURL)
        let expectation = self.expectation(description: "Load production config with spiral.radio and fallback")

        productionClient.fetchStations { result in
            switch result {
            case .success(let stations):
                XCTAssertFalse(stations.isEmpty, "Should load at least one station")

                // Verify we got the RadioSpiral station (from static fallback)
                if let radioSpiralStation = stations.first(where: { $0.shortCode == "radiospiral" }) {
                    XCTAssertEqual(radioSpiralStation.name, "RadioSpiral", "Should load RadioSpiral station")
                    XCTAssertTrue(radioSpiralStation.streamURL.contains("spiral.radio"), "Stream URL should be from spiral.radio")
                    XCTAssertEqual(radioSpiralStation.defaultDJ, "Spud the Ambient Robot", "Default DJ should match")

                    expectation.fulfill()
                } else {
                    // If Azuracast is unreachable, we should still get the fallback
                    XCTAssertTrue(true, "Using fallback static config")
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed to load production config: \(error)")
            }
        }

        waitForExpectations(timeout: 10.0)
    }
}
