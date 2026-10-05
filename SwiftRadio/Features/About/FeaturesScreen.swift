//
//  FeaturesScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Displays `Config.Features.items` as an inset-grouped list of
/// icon + title + subtitle rows. Rows are display-only.
struct FeaturesScreen: View {

    /// A fork can repeat a title, or two translations can coincide; ids stay unique regardless.
    private static let rows: [(id: String, item: FeatureItem)] =
        Array(zip(ConfiguredRowID.make(Config.Features.items.map(\.title)), Config.Features.items))

    var body: some View {
        List(Self.rows, id: \.id) { row in
            let item = row.item
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(uiColor: Config.tintColor))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .contentMargins(.top, 20, for: .scrollContent)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Text(Content.Features.title))
    }
}
