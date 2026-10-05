//
//  StationInfoScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Pushed station detail: artwork, name, descriptions, and an in-app "Visit Website" link.
/// SwiftUI successor to InfoDetailViewController.
@MainActor struct StationInfoScreen: View {
    let station: SwiftRadioCore.RadioStation
    @State private var showSafari = false
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ArtworkView(station: station, cornerRadius: 20)
                    .frame(width: 160, height: 160)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                VStack(spacing: 4) {
                    Text(station.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(station.desc)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 24)
                separator
                Text(longDescription)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
                if websiteURL != nil {
                    separator
                    Button { showSafari = true } label: {
                        HStack {
                            HStack(spacing: 10) {
                                Image(systemName: "safari")
                                    .font(.system(size: 22))
                                Text(Content.StationDetail.visitWebsite)
                                    .font(.body)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(Color(uiColor: Config.tintColor).opacity(0.3))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("stationWebsite")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GradientBackground())
        .navigationTitle(Content.StationDetail.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSafari) {
            if let url = websiteURL {
                SafariView(url: url)
            }
        }
    }

    private var longDescription: String {
        station.longDesc.isEmpty ? Content.StationDetail.defaultDescription : station.longDesc
    }

    private var websiteURL: URL? {
        guard station.hasValidWebsite, let website = station.website else { return nil }
        return URL(string: website)
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(height: 1 / displayScale)
    }
}
