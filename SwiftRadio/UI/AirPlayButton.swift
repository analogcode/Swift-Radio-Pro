//
//  AirPlayButton.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import AVKit
import SwiftUI

/// The system AirPlay route picker, tinted like the old AVRoutePickerView in ControlsView.
@MainActor struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = Config.tintColor
        picker.tintColor = Config.tintColor.withAlphaComponent(0.7)
        return picker
    }

    func updateUIView(_ picker: AVRoutePickerView, context: Context) {}
}
