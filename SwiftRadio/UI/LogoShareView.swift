//
//  LogoShareView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Off-screen share card (logo, album art, shoutout, track) rendered to a UIImage for the
/// share sheet. SwiftUI replacement for LogoShareView.xib + UIGraphicsImageRenderer.
@MainActor struct LogoShareView: View {
    let artwork: UIImage?
    let shoutout: String
    let track: String?
    let artist: String?

    var body: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 56)
            Group {
                if let artwork {
                    Image(uiImage: artwork).resizable().scaledToFill()
                } else {
                    Image("stationImage").resizable().scaledToFill()
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(spacing: 4) {
                Text(shoutout).font(.headline)
                if let track { Text(track).font(.subheadline) }
                if let artist { Text(artist).font(.subheadline).foregroundStyle(.secondary) }
            }
            .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 375)
        .background(Color.black)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    /// Renders the card off-screen; on failure the share carries the shoutout text only.
    func rendered(scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.uiImage
    }
}
