//
//  LibrariesScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//


import SwiftUI

/// Lists `Config.Libraries.items`, one section per library with two rows
/// (repository name + description, then owner login). Metadata is fetched
/// from the GitHub API in parallel via a task group; failures degrade to the
/// configured names. Tapping a row opens the repo/owner page in a Safari sheet.
struct LibrariesScreen: View {

    @State private var repositories: [String: GitHubClient.Repository] = [:]
    @State private var isLoading = true
    @State private var safariURL: URL?

    private let client = GitHubClient()

    /// A fork can list the same repository twice; ids stay unique while fetches share a key.
    private static let rows: [(id: String, item: LibraryItem)] = {
        let items = Config.Libraries.items
        return Array(zip(ConfiguredRowID.make(items.map(key(for:))), items))
    }()

    var body: some View {
        List {
            ForEach(Self.rows, id: \.id) { row in
                let item = row.item
                let fetched = repositories[Self.key(for: item)]
                Section {
                    Button {
                        safariURL = fetched?.htmlURL ?? Self.fallbackRepoURL(for: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                // Same fallbacks as the reference list when the fetch fails.
                                Text(fetched?.name ?? Self.key(for: item)).font(.headline)
                                Text(fetched?.description ?? Content.Common.noDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                            Spacer()
                            disclosureIndicator
                        }
                    }
                    Button {
                        safariURL = fetched?.owner.htmlURL ?? Self.fallbackOwnerURL(for: item)
                    } label: {
                        HStack {
                            Label("@" + (fetched?.owner.login ?? item.owner), systemImage: "person.circle")
                                .foregroundStyle(.primary)
                            Spacer()
                            disclosureIndicator
                        }
                    }
                }
            }
            .tint(Color(uiColor: Config.tintColor))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(Text(Content.Libraries.title))
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

    private var disclosureIndicator: some View {
        Image(systemName: "chevron.forward")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }

    /// Bridges the optional `safariURL` state to a `sheet(isPresented:)` binding.
    private var safariSheetPresented: Binding<Bool> {
        Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )
    }

    /// Fetches every configured repository concurrently. Individual failures
    /// yield `nil` so the row falls back to the configured names.
    private func load() async {
        var fetched: [String: GitHubClient.Repository] = [:]
        await withTaskGroup(of: (String, GitHubClient.Repository?).self) { group in
            for item in Config.Libraries.items {
                group.addTask {
                    (Self.key(for: item), try? await client.repository(owner: item.owner, name: item.repo))
                }
            }
            for await (key, repository) in group {
                fetched[key] = repository
            }
        }
        repositories = fetched
        isLoading = false
    }

    nonisolated private static func key(for item: LibraryItem) -> String {
        "\(item.owner)/\(item.repo)"
    }

    private static func fallbackRepoURL(for item: LibraryItem) -> URL? {
        URL(string: "https://github.com/\(item.owner)/\(item.repo)")
    }

    private static func fallbackOwnerURL(for item: LibraryItem) -> URL? {
        URL(string: "https://github.com/\(item.owner)")
    }
}
