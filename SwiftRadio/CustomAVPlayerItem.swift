//
//  CustomAVPlayerItem.swift
//  KonbiniRadio
//
//  Created by Xavier Daleau on 25/07/2016.
//
import MediaPlayer
import Foundation


protocol CustomAVPlayerItemDelegate {
    func onMetaData(metaData:[AVMetadataItem]?)
}

//*****************************************************************
// Makes sure that observers are removed before deallocation
//*****************************************************************

class CustomAVPlayerItem: AVPlayerItem {
    
    var delegate : CustomAVPlayerItemDelegate?
    
    init(URL:NSURL)
    {
        if kDebugLog {print("CustomAVPlayerItem.init")}
        super.init(asset: AVAsset(URL: URL) , automaticallyLoadedAssetKeys:[])
        addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit{        
        if kDebugLog {print("CustomAVPlayerItem.deinit")}
        removeObserver(self, forKeyPath: "timedMetadata")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let avpItem: AVPlayerItem = object as? AVPlayerItem {
            if keyPath == "timedMetadata" {                
                delegate?.onMetaData(avpItem.timedMetadata)
            }
        }
    }
}
