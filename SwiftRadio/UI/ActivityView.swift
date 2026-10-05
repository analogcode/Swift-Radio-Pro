//
//  ActivityView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Thin UIKit share sheet. ShareLink cannot transfer a mixed text + image payload, so the
/// shoutout string and the composed LogoShareView image go through UIActivityViewController.
@MainActor struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
