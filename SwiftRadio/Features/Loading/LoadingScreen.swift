//
//  LoadingScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Presents bootstrap progress or a recoverable catalog-loading failure.
@MainActor struct LoadingScreen: View {
    let error: String?
    let retry: () async -> Void

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 24) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .accessibilityHidden(true)
                if let error {
                    Text(Content.Loader.errorTitle).font(.headline)
                    Text(error).multilineTextAlignment(.center)
                    Button(Content.Loader.retryButton) { Task { await retry() } }
                        .buttonStyle(.bordered)
                } else {
                    ProgressView(Content.Stations.loadingMessage)
                }
            }
            .padding()
        }
    }
}
