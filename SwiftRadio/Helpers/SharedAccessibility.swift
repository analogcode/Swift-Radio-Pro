//
//  SharedAccessibility.swift
//  SwiftRadio
//
//  Created by mihail on 06.05.2025.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

enum SharedAccessibility {
    
    enum MenuViewController {
        static let menuViewCloseBtn = "menuViewCloseBtn"
        static let menuViewRadioLogo = "menuViewRadioLogo"
        static let menuViewAboutBtn = "menuViewAboutBtn"
        static let menuViewWebsiteBtn = "menuViewWebsiteBtn"
        static let menuViewNames = "menuViewNames"
        
    }
    
    enum StationsViewController {
        
        static let stationsTableView = "stationsTableView"
        static func stationCell(at index: Int) -> String {
            return "station_cell_\(index)"
        }
        static let nowPlayingBottomButton = "nowPlayingBottomButton"
        static let nowPlayingTitleLabel = "nowPlayingTitleLabel"
        static let nowPlayingSubtitleLabel = "nowPlayingSubtitleLabel"

//      TODO: добавить ID для Title, Subtitle, AlbumCover внутри каждой Cell

    }
    
    enum NowPlayingViewController {
        static let albumImageView = "albumImageView"
        static let stationDescriptionLabel = "stationDescriptionLabel"
        static let previousButton = "previousButton"
        static let playingButton = "playingButton"
        static let stopButton = "stopButton"
        static let nextButton = "nextButton"
        static let mpVolumeSlider = "mpVolumeSlider"
        static let songLabel = "songLabel"
        static let artistLabel = "artistLabel"
        static let nowPlayingRadioLogo = "nowPlayingRadioLogo"
        static let airPlayButton = "AirPlay"
        static let shareStationBtn = "shareStationBtn"
        static let moreInfoBtn = "moreInfoBtn"
        
        
        //не используются?
        static let nowPlayingImageView = "nowPlayingImageView"
        static let nowPlayingLabel = "nowPlayingLabel"
        static let volumeParentView = "volumeParentView"
    }
    
    enum InfoDetailViewController {
        
        static let stationImageView = "stationImageView"
        static let stationNameLabel = "stationNameLabel"
        static let stationDescriptionLabel = "stationDescriptionLabel"
        static let okayButton = "okayButton"

//      TODO: не получается определить элемент на экране 'LongDescriptionLabel'
//      static let stationLongDescriptionLabel = "stationLongDescriptionLabel"
        
    }
    
    enum AboutViewController {
        static let aboutAppViewRadioLogo = "aboutAppViewRadioLogo"
        static let aboutAppViewLabel = "aboutAppViewLabel"
        static let aboutAppViewVersionLabel = "aboutAppViewVersionLabel"
        static let aboutAppViewWebsiteBtn = "aboutAppViewWebsiteBtn"
        static let aboutAppViewEmailMeBtn = "aboutAppViewEmailMeBtn"
        static let aboutAppViewOkayBtn = "aboutAppViewOkayBtn"

//      TODO: не получается определить элемент 'Features:'
    }
    
   
}
