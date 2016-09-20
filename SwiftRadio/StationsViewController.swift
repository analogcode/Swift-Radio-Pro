//
//  StationsViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/19/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class StationsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stationNowPlayingButton: UIButton!
    @IBOutlet weak var nowPlayingAnimationImageView: UIImageView!
    
    var stations = [RadioStation]()
    var currentStation: RadioStation?
    var currentTrack: Track?
    var refreshControl: UIRefreshControl!
    var firstTime = true
    
    var searchedStations = [RadioStation]()
    var searchController : UISearchController!
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register 'Nothing Found' cell xib
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        
        // preferredStatusBarStyle()
        
        // Load Data
        loadStationsFromJSON()
        
        // Setup TableView
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        // Setup Pull to Refresh
        setupPullToRefresh()
        
        // Create NowPlaying Animation
        createNowPlayingAnimation()
        
        // Set AVFoundation category, required for background audio
        var error: NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            if kDebugLog { print("Failed to set audio session category.  Error: \(error)") }
        }
        
        // Set audioSession as active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error2 as NSError {
            if kDebugLog { print("audioSession setActive error \(error2)") }
        }
        
        // Setup Search Bar
        setupSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "Swift Radio"
        
        // If a station has been selected, create "Now Playing" button to get back to current station
        if !firstTime {
            createNowPlayingBarButton()
        }
        
        // If a track is playing, display title & artist information and animation
        if currentTrack != nil && currentTrack!.isPlaying {
            let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
            stationNowPlayingButton.setTitle(title, for: .normal)
            nowPlayingAnimationImageView.startAnimating()
        } else {
            nowPlayingAnimationImageView.stopAnimating()
            nowPlayingAnimationImageView.image = UIImage(named: "NowPlayingBars")
        }
        
    }

    //*****************************************************************
    // MARK: - Setup UI Elements
    //*****************************************************************
    
    func setupPullToRefresh() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName:UIColor.white])
        self.refreshControl.backgroundColor = UIColor.black
        self.refreshControl.tintColor = UIColor.white
        self.refreshControl.addTarget(self, action: #selector(StationsViewController.refresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    func createNowPlayingAnimation() {
        nowPlayingAnimationImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingAnimationImageView.animationDuration = 0.7
    }
    
    func createNowPlayingBarButton() {
        if self.navigationItem.rightBarButtonItem == nil {
            let btn = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action:#selector(self.nowPlayingBarButtonPressed))
            btn.image = UIImage(named: "btn-nowPlaying")
            self.navigationItem.rightBarButtonItem = btn
        }
    }
    
    func setupSearchController() {
        // Set the UISearchController
        searchController = UISearchController(searchResultsController: nil)
        
        if searchable {
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.searchBar.sizeToFit()
            
            // Add UISearchController to the tableView
            tableView.tableHeaderView = searchController?.searchBar
            tableView.tableHeaderView?.backgroundColor = UIColor.clear
            definesPresentationContext = true
            searchController.hidesNavigationBarDuringPresentation = false
            
            // Style the UISearchController
            searchController.searchBar.barTintColor = UIColor.clear
            searchController.searchBar.tintColor = UIColor.white
            
            // Hide the UISearchController
            tableView.setContentOffset(CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height), animated: false)
            
            // Set a black keyborad for UISearchController's TextField
            let searchTextField = searchController.searchBar.value(forKey: "_searchField") as! UITextField
            searchTextField.keyboardAppearance = UIKeyboardAppearance.dark
        }

    }
    
    //*****************************************************************
    // MARK: - Actions
    //*****************************************************************
    
    func nowPlayingBarButtonPressed() {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    @IBAction func nowPlayingPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    func refresh(sender: AnyObject) {
        // Pull to Refresh
        stations.removeAll(keepingCapacity: false)
        loadStationsFromJSON()
        
        // Wait 2 seconds then refresh screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
            self.view.setNeedsDisplay()
        }
    }
    
    //*****************************************************************
    // MARK: - Load Station Data
    //*****************************************************************
    
    func loadStationsFromJSON() {
        
        // Turn on network indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Get the Radio Stations
        DataManager.getStationDataWithSuccess() { (data) in
            
            if kDebugLog { print("Stations JSON Found") }
            
            let json = JSON(data: data! as Data)
            
            if let stationArray = json["station"].array {
                
                for stationJSON in stationArray {
                    let station = RadioStation.parseStation(stationJSON: stationJSON)
                    self.stations.append(station)
                }
                
                // stations array populated, update table on main queue
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                    self.view.setNeedsDisplay()
                })
                
            } else {
                if kDebugLog { print("JSON Station Loading Error") }
            }
            
            // Turn off network indicator in status bar
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NowPlaying" {
            
            self.title = ""
            firstTime = false
            
            let nowPlayingVC = segue.destination as! NowPlayingViewController
            nowPlayingVC.delegate = self
            
            if let indexPath = (sender as? NSIndexPath) {
                // User clicked on row, load/reset station
                if searchController.isActive {
                    currentStation = searchedStations[indexPath.row]
                } else {
                    currentStation = stations[indexPath.row]
                }
                nowPlayingVC.currentStation = currentStation
                nowPlayingVC.newStation = true
            
            } else {
                // User clicked on a now playing button
                if let currentTrack = currentTrack {
                    // Return to NowPlaying controller without reloading station
                    nowPlayingVC.track = currentTrack
                    nowPlayingVC.currentStation = currentStation
                    nowPlayingVC.newStation = false
                } else {
                    // Issue with track, reload station
                    nowPlayingVC.currentStation = currentStation
                    nowPlayingVC.newStation = true
                }
            }
        }
    }
}

//*****************************************************************
// MARK: - TableViewDataSource
//*****************************************************************

extension StationsViewController: UITableViewDataSource {
    
    // MARK: - Table view data source
    @objc(tableView:heightForRowAtIndexPath:)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // The UISeachController is active
        if searchController.isActive {
            return searchedStations.count
            
        // The UISeachController is not active
        } else {
            if stations.count == 0 {
                return 1
            } else {
                return stations.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if stations.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFound", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationTableViewCell
            
            // alternate background color
            if indexPath.row % 2 == 0 {
                cell.backgroundColor = UIColor.clear
            } else {
                cell.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }
            
            // Configure the cell...
            let station = stations[indexPath.row]
            cell.configureStationCell(station: station)
            
            // The UISeachController is active
            if searchController.isActive {
                let station = searchedStations[indexPath.row]
                cell.configureStationCell(station: station)
                
            // The UISeachController is not active
            } else {
                let station = stations[indexPath.row]
                cell.configureStationCell(station: station)
            }
            
            return cell
        }
    }
}

//*****************************************************************
// MARK: - TableViewDelegate
//*****************************************************************

extension StationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !stations.isEmpty {
            
            // Set Now Playing Buttons
            let title = stations[indexPath.row].stationName + " - Now Playing..."
            stationNowPlayingButton.setTitle(title, for: .normal)
            stationNowPlayingButton.isEnabled = true
            
            performSegue(withIdentifier: "NowPlaying", sender: indexPath)
        }
    }
}

//*****************************************************************
// MARK: - NowPlayingViewControllerDelegate
//*****************************************************************

extension StationsViewController: NowPlayingViewControllerDelegate {
    
    func artworkDidUpdate(track: Track) {
        currentTrack?.artworkURL = track.artworkURL
        currentTrack?.artworkImage = track.artworkImage
    }
    
    func songMetaDataDidUpdate(track: Track) {
        currentTrack = track
        let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
        stationNowPlayingButton.setTitle(title, for: .normal)
    }
    
    func trackPlayingToggled(track: Track) {
        currentTrack?.isPlaying = track.isPlaying
    }

}

//*****************************************************************
// MARK: - UISearchControllerDelegate
//*****************************************************************

extension StationsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
    
        // Empty the searchedStations array
        searchedStations.removeAll(keepingCapacity: false)
    
        // Create a Predicate
        let searchPredicate = NSPredicate(format: "SELF.stationName CONTAINS[c] %@", searchController.searchBar.text!)
    
        // Create an NSArray with a Predicate
        let array = (self.stations as NSArray).filtered(using: searchPredicate)
    
        // Set the searchedStations with search result array
        searchedStations = array as! [RadioStation]
    
        // Reload the tableView
        self.tableView.reloadData()
    }
    
}
