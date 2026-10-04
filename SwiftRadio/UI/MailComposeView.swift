//
//  MailComposeView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MessageUI
import SwiftUI

/// A `UIViewControllerRepresentable` wrapper over `MFMailComposeViewController`.
/// The coordinator acts as the compose delegate and dismisses the sheet on finish.
struct MailComposeView: UIViewControllerRepresentable {

    /// Whether the device is configured to send email. Check before presenting.
    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    let subject: String
    let recipients: [String]

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject(subject)
        controller.setToRecipients(recipients)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    /// Compose delegate that dismisses the sheet for any result (sent, saved, cancelled, failed).
    /// The conformance is isolated to the main actor (SE-0470): MessageUI calls the delegate on the main thread.
    @MainActor final class Coordinator: NSObject, @MainActor MFMailComposeViewControllerDelegate {

        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}
