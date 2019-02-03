//
//  StationsViewController+CarPlay.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-02-02.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import UIKit

extension StationsViewController {
    func selectFromCarPlay(_ station: RadioStation) {
        radioPlayer.station = station
        handleRemoteStationChange()
    }
}
