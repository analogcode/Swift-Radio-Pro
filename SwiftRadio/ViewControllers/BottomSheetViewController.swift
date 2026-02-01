//
//  BottomSheetViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-14.
//  Copyright 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer

protocol BottomSheetViewControllerDelegate: AnyObject {
    func bottomSheet(_ controller: BottomSheetViewController, didSelect option: BottomSheetViewController.Option)
}

class BottomSheetViewController: UIViewController {
    
    enum Section: Int, CaseIterable {
        case stationInfo
        case music
        case share
        var title: String? {
            return nil
        }
    }
    
    enum Option {
        case info
        case share(UIImage?)
        case website
        case openInMusic(URL?)
        
        var title: String {
            switch self {
                case .info: return "About Station"
                case .share: return "Share Now Playing"
                case .website: return "Station Website"
                case .openInMusic: return "Play in Music App"
            }
        }
        
        var image: UIImage? {
            switch self {
                case .info: return UIImage(systemName: "info.circle")
                case .share: return UIImage(systemName: "square.and.arrow.up")
                case .website: return UIImage(systemName: "safari")
                case .openInMusic: return UIImage(systemName: "music.note")
            }
        }
    }
    
    weak var delegate: BottomSheetViewControllerDelegate?
    private let station: RadioStation
    private let player = FRadioPlayer.shared
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    init(station: RadioStation) {
        self.station = station
        super.init(nibName: nil, bundle: nil)
        
        if let sheet = sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.detents = [.medium()]
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getOptions(for section: Section) -> [Option] {
        switch section {
            case .stationInfo:
                var options: [Option] = [.info]
                if station.hasValidWebsite {
                    options.append(.website)
                }
                return options
            case .music:
                return [.openInMusic(nil)]
            case .share:
                return [.share(nil)]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupViews()
        
        player.addObserver(self)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let sheet = sheetPresentationController {
            let contentHeight = tableView.contentSize.height + view.safeAreaInsets.top + view.safeAreaInsets.bottom
            sheet.detents = [.custom { _ in contentHeight }]
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = sheet.detents.first?.identifier
            }
        }
    }
}

extension BottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        return getOptions(for: section).count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Section(rawValue: section)!
        return section.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let section = Section(rawValue: indexPath.section)!
        let option = getOptions(for: section)[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = option.title
        config.image = option.image
        
        // Disable OpenInMusic cell if no metadata
        if case .openInMusic = option {
            let hasMetadata = player.currentArtworkURL != nil
            cell.isUserInteractionEnabled = hasMetadata
            // Update text color
            config.textProperties.color = hasMetadata ? .label : .tertiaryLabel
            config.imageProperties.tintColor = hasMetadata ? .label : .tertiaryLabel
        }
        
        cell.contentConfiguration = config
        cell.tintColor = .label
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = Section(rawValue: indexPath.section)!
        let option = getOptions(for: section)[indexPath.row]
        delegate?.bottomSheet(self, didSelect: option)
        dismiss(animated: true)
    }
}

extension BottomSheetViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        // Handle detent changes if needed
    }
}

extension BottomSheetViewController: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        // Reload the music section to update cell state
        if let musicSection = Section.allCases.firstIndex(of: .music) {
            tableView.reloadSections(IndexSet(integer: musicSection), with: .none)
        }
    }
}
