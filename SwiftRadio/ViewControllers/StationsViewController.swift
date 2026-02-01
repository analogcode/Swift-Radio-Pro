//
//  StationsViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2023-06-24.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer
import NVActivityIndicatorView

protocol StationsViewControllerDelegate: AnyObject {
    func didSelectStation(_ station: RadioStation, from stationsViewController: StationsViewController)
    func didTapNowPlaying(_ stationsViewController: StationsViewController)
    func presentAbout(_ stationsViewController: StationsViewController)
}

class StationsViewController: BaseController, Handoffable {

    // MARK: - Delegate
    weak var delegate: StationsViewControllerDelegate?

    // MARK: - Properties
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared

    // MARK: - UI

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()

    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()

    private let animationView: NVActivityIndicatorView = {
        let activityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .audioEqualizer, color: .white, padding: nil)
        NSLayoutConstraint.activate([
            activityIndicatorView.widthAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])
        return activityIndicatorView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        tableView.register(StationTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    override func loadView() {
        super.loadView()
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonDisplayMode = .minimal

        // NavigationBar items
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon-hamburger"), style: .plain, target: self, action: #selector(handleMenuTap))

        // Setup Player
        player.addObserver(self)
        manager.addObserver(self)

        // Setup Handoff User Activity
        setupHandoffUserActivity()

        // Setup Search Bar
        setupSearchController()

        // Set defaults station if the app started from CarPlay
        updateNowPlayingBarButton(station: manager.currentStation)
        updateHandoffUserActivity(userActivity, station: manager.currentStation)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Swift Radio"
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

    private func updateNowPlayingBarButton(station: RadioStation?) {
        guard station != nil else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        guard navigationItem.rightBarButtonItem == nil else { return }
        let barButton = UIBarButtonItem(customView: animationView)
        barButton.target = self
        barButton.action = #selector(nowPlayingBarButtonPressed)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(nowPlayingBarButtonPressed))
        animationView.addGestureRecognizer(tapGesture)
        animationView.isUserInteractionEnabled = true

        navigationItem.rightBarButtonItem = barButton
        startNowPlayingAnimation(player.isPlaying)
    }

    private func startNowPlayingAnimation(_ animate: Bool) {
        animate ? animationView.startAnimating() : animationView.stopAnimating()
    }

    @objc private func nowPlayingBarButtonPressed() {
        delegate?.didTapNowPlaying(self)
    }

    @objc func handleMenuTap() {
        delegate?.presentAbout(self)
    }

    private func selectStation(_ station: RadioStation) {
        delegate?.didSelectStation(station, from: self)
    }

    override func setupViews() {
        super.setupViews()

        tableView.addSubview(refreshControl)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

// MARK: - TableViewDataSource

extension StationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90.0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
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
            let cell = tableView.dequeueReusableCell(for: indexPath) as StationTableViewCell

            // alternate background color
            cell.backgroundColor = (indexPath.row % 2 == 0) ? .clear : .black.withAlphaComponent(0.2)

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

        selectStation(station)
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
        updateHandoffUserActivity(userActivity, station: manager.currentStation)
    }
}

extension StationsViewController: StationsManagerObserver {

    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        tableView.reloadData()
    }

    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        updateNowPlayingBarButton(station: station)
    }
}
