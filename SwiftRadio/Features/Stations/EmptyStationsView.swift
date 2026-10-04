//
//  EmptyStationsView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Shown in place of the station list while the catalog is empty.
@MainActor struct EmptyStationsView: View {
    var body: some View {
        // The reference's empty-catalog cell shows this same string.
        Text(Content.Stations.loadingMessage)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
