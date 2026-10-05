//
//  GradientBackground.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Uses the template's native gradient primitive. SwiftUI's LinearGradient interpolates
/// the diagonal differently in a tall rectangle, even with identical normalized endpoints.
@MainActor struct GradientBackground: View {
    var body: some View {
        NativeGradient().ignoresSafeArea().accessibilityHidden(true)
    }
}

private struct NativeGradient: UIViewRepresentable {
    func makeUIView(context: Context) -> GradientView {
        let view = GradientView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: GradientView, context: Context) {
        let gradient = view.layer as! CAGradientLayer
        gradient.backgroundColor = UIColor.black.cgColor
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.colors = [0.3, 0.15, 0.05].map {
            Config.gradientColor.withAlphaComponent($0).cgColor
        } + [UIColor.clear.cgColor]
        gradient.locations = [0, 0.3, 0.6, 1]
    }

    final class GradientView: UIView {
        override class var layerClass: AnyClass { CAGradientLayer.self }
    }
}
