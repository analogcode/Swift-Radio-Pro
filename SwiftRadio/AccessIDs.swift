//
//  AccessIDs.swift
//  SwiftRadio
//
//  Created by arthur on 12.11.2024.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import Foundation

public enum AccessIDs {
    public enum PopupInfoView {
        public static let popupCloseButton = "popupCloseButton"
        public static let popupCompanyLogo = "popupCompanyLogo"
        public static let popupAboutButton = "popupAboutButton"
        public static let popupWebsiteButton = "popupWebsiteButton"
        public static let popupProjectLabel = "popupProjectLabel"
        public static let popipProjectAuthor = "popupAuthorLabel"
    }
    
    public enum AboutView {
        public static let aboutCompanyLogo = "aboutLogoImage"
        public static let aboutVersionLabel = "aboutVersionLabel"
        public static let aboutAppNameLabel = "aboutAppNameLabel"
        public static let aboutDescriptionLabel = "aboutDescription"
        public static let aboutWebsiteButton = "aboutWebsiteButton"
        public static let aboutEmailButton = "aboutEmailButton"
        public static let aboutOkayButton = "aboutOkayButton"
    }
    
    public enum PlaybackView {
        public static let playbackSongImage = "playbackSongImageView"
        public static let playbackPreviousButton = "playbackPreviousButton"
        public static let playbackNextButton = "playbackNextButton"
        public static let playbackPlayPauseButton = "playbackPlayButton"
        public static let playbackStopButton = "playbackStopButton"
        public static let playbackSlider = "playbackVolumeSlider"
        public static let playbackIconVolMin = "playbackVolMinImage"
        public static let playbackIconVolMax = "playbackVolMaxImage"
        public static let playbackSongName = "playbackSongNameLabel"
        public static let playbackArtistName = "playbackArtistLabel"
        public static let playbackCompanyLogo = "playbackCompanyButton"
        public static let playbackStationDescription = "playbackDescription"
        public static let playbackShareButton = "playbackShareButton"
        public static let playbackInfoButton = "playbackInfoButton"
        public static let playbackAirPlayButton = "playbackAirPlayButton"
    }
    
    public enum InfoView {
        public static let infoStationImage = "infoStationImage"
        public static let infoStationTitle = "infoStationTitle"
        public static let infoStationSubtitle = "infoStationSubtitleLabel"
        public static let infoStationDescription = "infoStationDescription"
        public static let infoOkayButton = "infoOkayButton"
    }
}
