//
//  AboutViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MessageUI

protocol AboutViewControllerDelegate: AnyObject {
    func didTapEmailButton(_ aboutViewController: AboutViewController)
    func didTapWebsiteButton(_ aboutViewController: AboutViewController)
}

class AboutViewController: UIViewController {
    
    weak var delegate: AboutViewControllerDelegate?
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    // MARK: - IBActions
    
    @IBAction func emailButtonDidTouch(_ sender: UIButton) {
        delegate?.didTapEmailButton(self)
    }
    
    @IBAction func websiteButtonDidTouch(_ sender: UIButton) {
        delegate?.didTapWebsiteButton(self)
    }

  }

// MARK: - MFMailComposeViewController Delegate

extension AboutViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
