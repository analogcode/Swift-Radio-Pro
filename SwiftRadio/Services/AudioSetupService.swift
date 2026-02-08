//
//  AudioSetupService.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 1/25/25.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import AVFAudio
import MediaPlayer
import FRadioPlayer

class AudioSetupService {
    static let shared = AudioSetupService()
    
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared
    
    private init() {}
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            if Config.debugLog {
                print("Failed to configure audio session: \(error.localizedDescription)")
            }
        }
    }
    
    func setupFRadioPlayer() {
        player.isAutoPlay = true
        player.enableArtwork = true
        player.artworkAPI = iTunesAPI(artworkSize: 600)
    }
    
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            return .success
        }

        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.player.stop()
            return .success
        }
        commandCenter.stopCommand.isEnabled = false

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.player.isPlaying, self.player.duration == 0 {
                self.player.stop()
            } else {
                self.player.togglePlaying()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.manager.setNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.manager.setPrevious()
            return .success
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func updateLiveCommands(isLive: Bool) {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = !isLive
        commandCenter.stopCommand.isEnabled = isLive
    }

    func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            if Config.debugLog {
                print("audioSession could not be activated: \(error.localizedDescription)")
            }
        }
    }
}
