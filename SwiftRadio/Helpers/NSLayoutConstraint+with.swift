//
//  NSLayoutConstraint+with.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 1/19/25.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    func with(_ config: (NSLayoutConstraint) -> Void) -> NSLayoutConstraint {
        config(self)
        return self
    }
}
