//
//  ContributorsScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Shows GitHub contributors (sorted by contributions, descending) in a
/// 3-column grid: circular avatar, "#rank login", and commit count.
/// Tapping a cell opens the contributor's profile in a Safari sheet.
struct ContributorsScreen: View {

    let owner: String
    let repo: String

    @State private var contributors: [GitHubClient.Contributor] = []
    @State private var isLoading = true
    @State private var safariURL: URL?

    private let client = GitHubClient()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(contributors.enumerated()), id: \.element.id) { index, contributor in
                    Button {
                        safariURL = contributor.htmlURL
                    } label: {
                        cell(rank: index + 1, contributor: contributor)
                    }
                    .tint(Color(uiColor: Config.tintColor))
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(Text(Content.Contributors.title))
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await load()
        }
        .sheet(isPresented: safariSheetPresented) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }

    /// Bridges the optional `safariURL` state to a `sheet(isPresented:)` binding.
    private var safariSheetPresented: Binding<Bool> {
        Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )
    }

    @ViewBuilder
    private func cell(rank: Int, contributor: GitHubClient.Contributor) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: contributor.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.3)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
            Text("#\(rank) \(contributor.login)")
                .font(.caption)
                .lineLimit(1)
            Text(Content.Common.commits(contributor.contributions))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Loads contributors; any failure leaves the grid empty rather than crashing.
    private func load() async {
        let fetched = (try? await client.contributors(owner: owner, name: repo)) ?? []
        contributors = fetched.sorted { $0.contributions > $1.contributions }
        isLoading = false
    }
}
