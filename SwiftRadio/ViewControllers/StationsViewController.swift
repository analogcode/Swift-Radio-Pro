//
//  StationsViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/19/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import AVFoundation
import FRadioPlayer
import Spring

protocol StationsViewControllerDelegate: AnyObject {
    func pushNowPlayingController(_ stationsViewController: StationsViewController, newStation: Bool)
    func presentPopUpMenuController(_ stationsViewController: StationsViewController)
}

class StationsViewController: UIViewController, Handoffable {
    
    // MARK: - Delegate
    weak var delegate: StationsViewControllerDelegate?
    
    // MARK: - IB UI

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stationNowPlayingButton: UIButton!
    @IBOutlet weak var nowPlayingAnimationImageView: UIImageView!
    
    // MARK: - Properties
        
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared
    
    // MARK: - UI
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()
    
    private let refreshControl: UIRefreshControl = {
        return UIRefreshControl()
    }()
    
    // MARK: - ViewDidLoad
    
    @objc func handleMenuTap() {
        delegate?.presentPopUpMenuController(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register 'Nothing Found' cell xib
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        
        // NavigationBar items
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon-hamburger"), style: .plain, target: self, action: #selector(handleMenuTap))
        
        // Setup Player
        player.addObserver(self)
        manager.addObserver(self)
        
        // Setup TableView
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        
        // Setup Pull to Refresh
        setupPullToRefresh()
        
        // Create NowPlaying Animation
        createNowPlayingAnimation()
        
        // Setup Search Bar
        setupSearchController()
        
        // Setup Handoff User Activity
        setupHandoffUserActivity()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Swift Radio"
    }

    // MARK: - Setup UI Elements
    
    private func setupPullToRefresh() {
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [.foregroundColor: UIColor.white])
        refreshControl.backgroundColor = .black
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func createNowPlayingAnimation() {
        nowPlayingAnimationImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingAnimationImageView.animationDuration = 0.7
    }
    
    private func createNowPlayingBarButton() {
        guard navigationItem.rightBarButtonItem == nil else { return }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-nowPlaying"), style: .plain, target: self, action: #selector(nowPlayingBarButtonPressed))
    }
    
    // MARK: - Actions
    
    @objc func nowPlayingBarButtonPressed() {
        pushNowPlayingController()
    }
    
    @IBAction func nowPlayingPressed(_ sender: UIButton) {
        pushNowPlayingController()
    }
    
    @objc func refresh(sender: AnyObject) {
        // Pull to Refresh
        manager.fetch()
        
        // Wait 2 seconds then refresh screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.view.setNeedsDisplay()
        }
    }
    
    // MARK: - Segue
    
    func pushNowPlayingController(with station: RadioStation? = nil) {
        title = ""
        
        let newStation: Bool
        
        if let station = station {
            // User clicked on row, load/reset station
            newStation = station != manager.currentStation
            if newStation {
                manager.set(station: station)
            }
        } else {
            // User clicked on Now Playing button
            newStation = false
        }
        
        delegate?.pushNowPlayingController(self, newStation: newStation)
    }
    
    // Reset all properties to default
    private func resetCurrentStation() {
        nowPlayingAnimationImageView.stopAnimating()
        stationNowPlayingButton.setTitle("Choose a station above to begin", for: .normal)
        stationNowPlayingButton.isEnabled = false
        navigationItem.rightBarButtonItem = nil
    }
    
    // Update the now playing button title
    private func updateNowPlayingButton(station: RadioStation?) {
        
        guard let station = station else {
            return
        }
        
        var playingTitle = station.name + ": "
        
        if player.currentMetadata == nil {
            playingTitle += "Now playing ..."
        } else {
            playingTitle += station.trackName + " - " + station.artistName
        }
        
        stationNowPlayingButton.setTitle(playingTitle, for: .normal)
        stationNowPlayingButton.isEnabled = true
        createNowPlayingBarButton()
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingAnimationImageView.startAnimating() : nowPlayingAnimationImageView.stopAnimating()
    }
}

// MARK: - TableViewDataSource

extension StationsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            return manager.searchedStations.count
        } else {
            return manager.stations.isEmpty ? 1 : manager.stations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if manager.stations.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFound", for: indexPath) 
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationTableViewCell
            
            // alternate background color
            cell.backgroundColor = (indexPath.row % 2 == 0) ? UIColor.clear : UIColor.black.withAlphaComponent(0.2)
            
            let station = searchController.isActive ? manager.searchedStations[indexPath.row] : manager.stations[indexPath.row]
            cell.configureStationCell(station: station)
            
            return cell
        }
    }
}

// MARK: - TableViewDelegate

extension StationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let station = searchController.isActive ? manager.searchedStations[indexPath.item] : manager.stations[indexPath.item]
        
        pushNowPlayingController(with: station)
    }
}

// MARK: - UISearchControllerDelegate / Setup

extension StationsViewController: UISearchResultsUpdating {
    
    func setupSearchController() {
        guard Config.searchable else { return }
        
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text else { return }
        manager.updateSearch(with: filter)
        tableView.reloadData()
    }
}

// MARK: - FRadioPlayerObserver

extension StationsViewController: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        startNowPlayingAnimation(player.isPlaying)
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        updateNowPlayingButton(station: manager.currentStation)
        updateHandoffUserActivity(userActivity, station: manager.currentStation)
    }
}

extension StationsViewController: StationsManagerObserver {
    
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        self.tableView.reloadData()
    }
    
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        guard let station = station else {
            resetCurrentStation()
            return
        }
        
        updateNowPlayingButton(station: station)
    }
}
