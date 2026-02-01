//
//  LibrariesViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 1/25/25.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import UIKit
import SafariServices

final class LibrariesViewController: UITableViewController {
    
    // MARK: - Internal Model

    struct LibraryInfo {
        let owner: String
        let repo: String
        var name: String
        var description: String?

        var htmlURL: URL {
            URL(string: "https://github.com/\(owner)/\(repo)")!
        }
        var ownerURL: URL {
            URL(string: "https://github.com/\(owner)")!
        }
    }

    // MARK: - Properties

    private var libraries: [LibraryInfo] = Config.Libraries.items.map {
        LibraryInfo(owner: $0.owner, repo: $0.repo, name: "", description: nil)
    }
    
    // A simple activity indicator for loading
    private let spinner = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Content.Libraries.title
        navigationItem.largeTitleDisplayMode = .automatic
        
        // Register a default cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Add some space at the top via a minimal header
        addSpaceAtTopOfTable(24)
        
        // Setup spinner in the background view
        spinner.hidesWhenStopped = true
        tableView.backgroundView = spinner
        spinner.startAnimating()
        
        // Fetch data (in parallel) from GitHub
        Task {
            await fetchLibrariesData()
        }
    }
    
    private func addSpaceAtTopOfTable(_ height: CGFloat) {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height))
        headerView.backgroundColor = .clear
        tableView.tableHeaderView = headerView
    }
    
    // MARK: - Data Fetch
    
    /// Fetch name/description/html_url for each library from GitHub.
    private func fetchLibrariesData() async {
        do {
            // Run tasks in parallel with ThrowingTaskGroup
            try await withThrowingTaskGroup(of: (Int, String, String?).self) { group in
                for (index, lib) in libraries.enumerated() {
                    group.addTask {
                        let repo = try await NetworkService.fetchRepository(owner: lib.owner, repo: lib.repo)
                        return (index, repo.name, repo.description)
                    }
                }

                for try await (index, name, desc) in group {
                    libraries[index].name = name
                    libraries[index].description = desc
                }
            }
            
            // Reload the table on the main thread
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.tableView.reloadData()
            }
            
        } catch {
            // If any repo fetch fails, handle error here
            print("Error fetching library info:", error)
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                // Optionally show an alert or fallback UI
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        libraries.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let library = libraries[indexPath.section]
        
        var content = cell.defaultContentConfiguration()
        content.textProperties.numberOfLines = 0
        content.secondaryTextProperties.numberOfLines = 0
        
        switch indexPath.row {
            case 0:
                content.text = library.name.isEmpty ? "\(library.owner)/\(library.repo)" : library.name
                content.textProperties.font = .boldSystemFont(ofSize: 17)
                content.secondaryText = library.description ?? "No description"
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                
            case 1:
                content.text = "@\(library.owner)"
                content.image = UIImage(systemName: "person.circle")
                content.imageProperties.tintColor = .label
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
            default:
                break
        }
        
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let library = libraries[indexPath.section]
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
            case 0:
                let safariVC = SFSafariViewController(url: library.htmlURL)
                present(safariVC, animated: true)
            case 1:
                let safariVC = SFSafariViewController(url: library.ownerURL)
                present(safariVC, animated: true)
            default:
                break
        }
    }
}
