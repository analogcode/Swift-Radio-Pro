//
//  CustomAVPlayerItem.swift
//  KonbiniRadio
//
//  Created by Xavier Daleau on 25/07/2016.
//
import MediaPlayer
import Foundation


protocol CustomAVPlayerItemDelegate {
    func onMetaData(_ metaData:[AVMetadataItem]?)
}

//*****************************************************************
// Makes sure that observers are removed before deallocation
//*****************************************************************

class CustomAVPlayerItem: AVPlayerItem {
    
    var delegate : CustomAVPlayerItemDelegate?
    
    init(url URL:URL)
    {
        if kDebugLog {print("CustomAVPlayerItem.init")}
        super.init(asset: AVAsset(url: URL) , automaticallyLoadedAssetKeys:[])
        addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    deinit{        
        if kDebugLog {print("CustomAVPlayerItem.deinit")}
        removeObserver(self, forKeyPath: "timedMetadata")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let avpItem: AVPlayerItem = object as? AVPlayerItem {
            if keyPath == "timedMetadata" {                
                delegate?.onMetaData(avpItem.timedMetadata)
            }
        }
    }
}
