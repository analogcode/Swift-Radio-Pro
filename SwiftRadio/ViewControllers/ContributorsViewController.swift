//
//  ContributorsViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 1/25/25.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import UIKit
import SafariServices

struct Contributor: Decodable {
    let login: String
    let avatarURL: URL
    let htmlURL: URL
    let contributions: Int
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case contributions
    }
}

final class ContributorCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ContributorCell"
    
    // Avatar
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.layer.cornerRadius = 36
        return iv
    }()
    
    // Rank & Username: e.g., "#1 fethica"
    private let rankUsernameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    // Commits: e.g., "42 commits"
    private let commitsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(rankUsernameLabel)
        contentView.addSubview(commitsLabel)
        
        // Example Auto Layout
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        rankUsernameLabel.translatesAutoresizingMaskIntoConstraints = false
        commitsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Avatar: center top, fixed size
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 72),
            avatarImageView.heightAnchor.constraint(equalToConstant: 72),
            
            // Rank & username below the avatar
            rankUsernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            rankUsernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            rankUsernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            // Commits below username
            commitsLabel.topAnchor.constraint(equalTo: rankUsernameLabel.bottomAnchor, constant: 4),
            commitsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            commitsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(rank: Int, contributor: Contributor, avatar: UIImage?) {
        // #rank username
        rankUsernameLabel.text = "#\(rank) \(contributor.login)"
        
        // e.g., "42 commits"
        commitsLabel.text = "\(contributor.contributions) commits"
        
        // Set placeholder and load image using cache
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        avatarImageView.load(url: contributor.avatarURL, placeholder: UIImage(systemName: "person.crop.circle"))
    }
}

final class ContributorsViewController: UICollectionViewController {
    
    // MARK: - Public
    let owner: String
    let repo: String
    
    // MARK: - Private
    private var contributors: [Contributor] = []
    
    private let spinner = UIActivityIndicatorView(style: .large)
    
    // MARK: - Init
    
    init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
        
        // 3-column flow layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 8
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Content.Contributors.title
        navigationItem.largeTitleDisplayMode = .automatic
        
        // Add section insets for top spacing and horizontal margins
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(
            ContributorCell.self,
            forCellWithReuseIdentifier: ContributorCell.reuseIdentifier
        )
        
        collectionView.backgroundView = spinner
        spinner.startAnimating()
        
        Task {
            await fetchContributors()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            let totalSpacing: CGFloat = flowLayout.minimumInteritemSpacing * 2
            let horizontalInsets: CGFloat = flowLayout.sectionInset.left + flowLayout.sectionInset.right
            let availableWidth = collectionView.bounds.width - horizontalInsets - totalSpacing
            let itemWidth = floor(availableWidth / 3)
            flowLayout.itemSize = CGSize(width: itemWidth, height: 140)
        }
    }
    
    // MARK: - Data Fetch
    
    private func fetchContributors() async {
        do {
            let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contributors"
            guard let url = URL(string: urlString) else { return }
            
            // Make request
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Decode
            let decoded = try JSONDecoder().decode([Contributor].self, from: data)
            
            // Sort by contributions descending, or keep as is
            let sortedContribs = decoded.sorted { $0.contributions > $1.contributions }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.contributors = sortedContribs
                self.spinner.stopAnimating()
                self.collectionView.reloadData()
            }
        } catch {
            print("Failed to fetch contributors:", error)
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }
    }
    
    // MARK: - CollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contributors.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ContributorCell.reuseIdentifier,
            for: indexPath
        ) as? ContributorCell else {
            return UICollectionViewCell()
        }
        
        let contributor = contributors[indexPath.item]
        let rank = indexPath.item + 1
        
        // Configure cell with placeholder
        cell.configure(rank: rank, contributor: contributor, avatar: nil)
        
        // Style cell background
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = true
        
        return cell
    }
    
    // MARK: - CollectionView Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contributor = contributors[indexPath.item]
        let safariVC = SFSafariViewController(url: contributor.htmlURL)
        present(safariVC, animated: true)
    }
}
