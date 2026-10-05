//
//  CatalogListContent.swift
//  SwiftRadioCore
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// What a size-limited station list (the CarPlay list template) shows for the catalog's state.
/// Pure so the car's empty, failed and paged states are testable without a head unit.
public enum CatalogListContent: Equatable, Sendable {
    case loading
    case failed(String)
    /// Loaded, but the catalog has no stations.
    case empty
    /// The catalog split into pages that each fit the list limit. Every page but the last ends
    /// with a More row that opens the next one. `hiddenCount` stations did not fit even so.
    case stations(pages: [[RadioStation]], hiddenCount: Int)

    /// - Parameter maximumPageCount: how many list templates may be stacked for the catalog.
    public init(stations: [RadioStation], loadState: StationsStore.LoadState, maximumItemCount: Int,
                maximumPageCount: Int = 1) {
        guard stations.isEmpty else {
            self = Self.paged(stations, limit: max(1, maximumItemCount), pageCount: max(1, maximumPageCount))
            return
        }
        switch loadState {
        case .idle, .loading: self = .loading
        case .failed(let message): self = .failed(message)
        case .loaded: self = .empty
        }
    }

    /// Stations on the pages, in catalog order.
    public var visibleStations: [RadioStation] {
        guard case .stations(let pages, _) = self else { return [] }
        return pages.flatMap { $0 }
    }

    private static func paged(_ stations: [RadioStation], limit: Int, pageCount: Int) -> Self {
        var pages: [[RadioStation]] = []
        var remaining = stations[...]
        while !remaining.isEmpty {
            // The last page allowed, or the rest fitting whole, needs no More row. A one-item
            // limit has no room for one, so it truncates.
            let isLast = pages.count == pageCount - 1 || remaining.count <= limit || limit < 2
            let page = remaining.prefix(isLast ? limit : limit - 1)
            pages.append(Array(page))
            remaining = remaining.dropFirst(page.count)
            if isLast { break }
        }
        return .stations(pages: pages, hiddenCount: remaining.count)
    }
}
