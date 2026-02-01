//
//  FeaturesViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-25.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import UIKit

class FeaturesViewController: UITableViewController {
    
    // MARK: - Properties

    private let features = Config.Features.items
    
    // MARK: - Init
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = Content.Features.title
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView() 
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        features.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let feature = features[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        
        // Title
        content.text = feature.title
        content.textProperties.numberOfLines = 0
        content.textProperties.font = .boldSystemFont(ofSize: 17)
        
        // Subtitle
        content.secondaryText = feature.subtitle
        content.secondaryTextProperties.numberOfLines = 0
        content.secondaryTextProperties.font = .systemFont(ofSize: 15)
        content.secondaryTextProperties.color = .secondaryLabel
        
        // Icon (SF Symbol)
        if let symbolImage = UIImage(systemName: feature.icon) {
            content.image = symbolImage
            content.imageProperties.tintColor = .label
        }
        
        // Configure cell
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
}
