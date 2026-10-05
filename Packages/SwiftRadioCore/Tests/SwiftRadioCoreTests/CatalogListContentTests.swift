//
//  CatalogListContentTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
@testable import SwiftRadioCore

/// Covers what a head unit list shows for each catalog state and list-size limit.
struct CatalogListContentTests {
    private static func stations(_ count: Int) -> [RadioStation] {
        (0..<count).map { RadioStation(name: "S\($0)", streamURL: "https://example.com/\($0)", imageURL: "", desc: "") }
    }

    @Test func emptyCatalogReportsLoadProgress() {
        #expect(CatalogListContent(stations: [], loadState: .idle, maximumItemCount: 12) == .loading)
        #expect(CatalogListContent(stations: [], loadState: .loading, maximumItemCount: 12) == .loading)
        #expect(CatalogListContent(stations: [], loadState: .failed("offline"), maximumItemCount: 12) == .failed("offline"))
        #expect(CatalogListContent(stations: [], loadState: .loaded, maximumItemCount: 12) == .empty)
    }

    @Test func loadedStationsWinOverALaterRefreshState() {
        let stations = Self.stations(3)
        let expected = CatalogListContent.stations(pages: [stations], hiddenCount: 0)
        #expect(CatalogListContent(stations: stations, loadState: .failed("offline"), maximumItemCount: 12) == expected)
        #expect(CatalogListContent(stations: stations, loadState: .loading, maximumItemCount: 12) == expected)
    }

    /// A head unit that allows 12 rows must still reach all 30 stations: every page but the last
    /// keeps its final row for More, and no page exceeds the limit.
    @Test func catalogBeyondTheItemLimitIsPaged() {
        let stations = Self.stations(30)
        let content = CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 12,
                                         maximumPageCount: 4)
        guard case .stations(let pages, let hidden) = content else { Issue.record("\(content)"); return }
        #expect(pages.map(\.count) == [11, 11, 8])
        #expect(hidden == 0)
        #expect(content.visibleStations.map(\.id) == stations.map(\.id))
        for (index, page) in pages.enumerated() {
            let rows = page.count + (index < pages.count - 1 ? 1 : 0) // Stations plus More.
            #expect(rows <= 12)
        }
    }

    /// The limit can change while connected (driving vs parked); the pages follow it.
    @Test func aChangedLimitRepages() {
        let stations = Self.stations(30)
        let parked = CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 24, maximumPageCount: 4)
        let driving = CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 12, maximumPageCount: 4)
        #expect(parked == .stations(pages: [Array(stations[0..<23]), Array(stations[23...])], hiddenCount: 0))
        #expect(parked != driving)
        #expect(driving.visibleStations == stations)
    }

    /// Past the template depth budget the last page takes the full limit and the rest is hidden;
    /// a limit with no room for a More row falls back to plain truncation.
    @Test func pagingStopsAtTheDepthBudget() {
        let stations = Self.stations(30)
        #expect(CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 6, maximumPageCount: 4)
                == .stations(pages: [Array(stations[0..<5]), Array(stations[5..<10]), Array(stations[10..<15]),
                                     Array(stations[15..<21])], hiddenCount: 9))
        #expect(CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 12)
                == .stations(pages: [Array(stations.prefix(12))], hiddenCount: 18))
        // A nonsensical limit still shows something rather than an empty list.
        #expect(CatalogListContent(stations: stations, loadState: .loaded, maximumItemCount: 0, maximumPageCount: 4)
                == .stations(pages: [[stations[0]]], hiddenCount: 29))
    }
}
