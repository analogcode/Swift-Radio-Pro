import UIKit
import MediaPlayer
import FRadioPlayer
import AVFAudio

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var coordinator: MainCoordinator?
    
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // FRadioPlayer config
        setupFRadioPlayer()
        
        // AudioSession & RemotePlay
        setupAudioSessionAndRemoteControls()
        
        // UI Setup
        setupUIAppearance()
        
        // Start the coordinator
        setupCoordinator(windowScene: windowScene)
    }
    
    private func setupFRadioPlayer() {
        player.isAutoPlay = true
        player.enableArtwork = true
        player.artworkAPI = iTunesAPI(artworkSize: 600)
    }
    
    private func setupAudioSessionAndRemoteControls() {
        activateAudioSession()
        setupRemoteCommandCenter()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    private func setupUIAppearance() {
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().prefersLargeTitles = true
    }
    
    private func setupCoordinator(windowScene: UIWindowScene) {
        coordinator = MainCoordinator(navigationController: UINavigationController())
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = coordinator?.navigationController
        window?.makeKeyAndVisible()
        
        coordinator?.start()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    // MARK: - Remote Controls
    
    private func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            return .success
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            return .success
        }
        
        // Add handler for Toggle Command
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.player.togglePlaying()
            return .success
        }
        
        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.manager.setNext()
            return .success
        }
        
        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.manager.setPrevious()
            return .success
        }
    }
    
    // MARK: - Activate Audio Session
    
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            if Config.debugLog {
                print("audioSession could not be activated: \(error.localizedDescription)")
            }
        }
    }
}
