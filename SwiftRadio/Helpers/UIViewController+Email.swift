//
//  UIViewController+Email.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-24.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import MessageUI

extension MFMailComposeViewControllerDelegate where Self: UIViewController {

    var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    func configureMailComposeViewController(recepients: [String], subject: String, messageBody: String) -> MFMailComposeViewController {

        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self

        mailComposerVC.setToRecipients(recepients)
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody(messageBody, isHTML: false)

        return mailComposerVC
    }
}

extension UIViewController {
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: Content.Common.couldNotSendEmail, message: Content.Common.emailErrorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Content.Common.ok, style: .cancel, handler: nil)

        sendMailErrorAlert.addAction(cancelAction)
        present(sendMailErrorAlert, animated: true, completion: nil)
    }
}
