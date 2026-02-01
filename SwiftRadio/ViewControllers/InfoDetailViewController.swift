//
//  InfoDetailViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class InfoDetailViewController: BaseController {

    private struct Link {
        let title: String
        let image: UIImage?
        let url: URL
    }

    private let station: RadioStation
    private var links: [Link] = []

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let stationImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "stationImage"))
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2, compatibleWith: .init(legibilityWeight: .bold))
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .init(white: 1, alpha: 0.7)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let longDescLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .init(white: 1, alpha: 0.85)
        label.numberOfLines = 0
        return label
    }()

    init(station: RadioStation) {
        self.station = station
        super.init(nibName: nil, bundle: nil)

        if station.hasValidWebsite,
           let website = station.website,
           let url = URL(string: website) {
            links.append(Link(title: "Visit the official station page", image: UIImage(systemName: "safari"), url: url))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About Station"
        setupLayout()
        populateData()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        // -- Image --
        let imageContainer = UIView()
        imageContainer.addSubview(stationImageView)
        NSLayoutConstraint.activate([
            stationImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 24),
            stationImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            stationImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            stationImageView.widthAnchor.constraint(equalToConstant: 160),
            stationImageView.heightAnchor.constraint(equalToConstant: 160),
        ])
        contentStack.addArrangedSubview(imageContainer)

        // -- Name & Desc --
        let titleStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4
        titleStack.alignment = .center
        contentStack.addArrangedSubview(titleStack)
        contentStack.setCustomSpacing(16, after: imageContainer)

        // -- Separator --
        contentStack.setCustomSpacing(24, after: titleStack)
        contentStack.addArrangedSubview(makeSeparator())

        // -- Long Description --
        let descContainer = UIView()
        longDescLabel.translatesAutoresizingMaskIntoConstraints = false
        descContainer.addSubview(longDescLabel)
        NSLayoutConstraint.activate([
            longDescLabel.topAnchor.constraint(equalTo: descContainer.topAnchor, constant: 20),
            longDescLabel.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20),
            longDescLabel.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20),
            longDescLabel.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: -20),
        ])
        contentStack.addArrangedSubview(descContainer)

        // -- Links --
        if !links.isEmpty {
            contentStack.addArrangedSubview(makeSeparator())

            for (index, link) in links.enumerated() {
                let button = makeLinkButton(link, tag: index)
                contentStack.addArrangedSubview(button)
            }
        }
    }

    // MARK: - Data

    private func populateData() {
        nameLabel.text = station.name
        descLabel.text = station.desc

        let text = station.longDesc.isEmpty
            ? "You are listening to Swift Radio. This is a sweet open source project. Tell your friends, swiftly!"
            : station.longDesc
        longDescLabel.text = text

        station.getImage { [weak self] image in
            self?.stationImageView.image = image
        }
    }

    // MARK: - Helpers

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .init(white: 1, alpha: 0.15)
        separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        let container = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            separator.topAnchor.constraint(equalTo: container.topAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func makeLinkButton(_ link: Link, tag: Int) -> UIView {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString(link.title)
        titleAttr.font = .preferredFont(forTextStyle: .body, compatibleWith: .init(legibilityWeight: .bold))
        config.attributedTitle = titleAttr
        config.image = link.image
        config.baseForegroundColor = .white
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)

        let button = UIButton(configuration: config)
        button.tag = tag
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(linkTapped(_:)), for: .touchUpInside)

        // Add a chevron on the trailing side
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .init(white: 1, alpha: 0.3)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        button.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
        ])

        return button
    }

    @objc private func linkTapped(_ sender: UIButton) {
        guard sender.tag < links.count else { return }
        UIApplication.shared.open(links[sender.tag].url)
    }
}
