//
//  AboutViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

protocol AboutViewControllerDelegate: AnyObject {
    func aboutViewController(_ controller: AboutViewController, didSelectItem item: InfoItem)
}

class AboutViewController: UITableViewController {

    // MARK: - Properties

    weak var delegate: AboutViewControllerDelegate?
    private var sections: [InfoSection] = []

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

        // Navigation
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonDisplayMode = .minimal
        title = Content.About.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissController))

        // Table setup
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .systemGroupedBackground

        // Header & Footer
        setupTableHeaderView()
        setupFooter()

        // Build data
        setupSections()
    }

    @objc private func dismissController() {
        dismiss(animated: true)
    }

    // MARK: - Setup: Header

    /// Creates a custom header with a bold title and descriptive text about Swift Radio.
    private func setupTableHeaderView() {
        let headerView = UIView()

        let aboutLabel = UILabel()
        aboutLabel.font = .systemFont(ofSize: 16)
        aboutLabel.textColor = .secondaryLabel
        aboutLabel.numberOfLines = 0
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false

        aboutLabel.attributedText = makeAboutText()

        headerView.addSubview(aboutLabel)

        NSLayoutConstraint.activate([
            aboutLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 24),
            aboutLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            aboutLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            aboutLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -24)
        ])

        // Force a layout pass so Auto Layout can calculate correct sizes
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        // Measure and update the header's frame
        let targetSize = CGSize(width: tableView.bounds.width, height: 0)
        let size = headerView.systemLayoutSizeFitting(targetSize,
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        headerView.frame.size.height = size.height
        tableView.tableHeaderView = headerView
    }

    private func makeAboutText() -> NSAttributedString {
        let (plainText, boldRanges) = Self.parseBoldMarkers(Content.About.headerText)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let attributed = NSMutableAttributedString(string: plainText, attributes: [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ])

        for range in boldRanges {
            attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: range)
        }

        return attributed
    }

    /// Parses `**bold**` markers from a string, returning the plain text and the NSRanges of bold segments.
    private static func parseBoldMarkers(_ input: String) -> (String, [NSRange]) {
        var plain = ""
        var boldRanges: [NSRange] = []
        var remaining = input[...]

        while let start = remaining.range(of: "**") {
            plain += remaining[..<start.lowerBound]
            remaining = remaining[start.upperBound...]

            guard let end = remaining.range(of: "**") else {
                plain += "**"
                break
            }

            let boldText = String(remaining[..<end.lowerBound])
            let location = plain.utf16.count
            plain += boldText
            boldRanges.append(NSRange(location: location, length: boldText.utf16.count))
            remaining = remaining[end.upperBound...]
        }

        plain += remaining
        return (plain, boldRanges)
    }

    // Re-calc header size on layout changes (like rotation)
    // TODO: Try to remove this workaround
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let header = tableView.tableHeaderView else { return }

        // Measure again in case the width has changed
        let targetSize = CGSize(width: tableView.bounds.width, height: 0)
        let newSize = header.systemLayoutSizeFitting(targetSize,
                                                     withHorizontalFittingPriority: .required,
                                                     verticalFittingPriority: .fittingSizeLevel)
        // If the size changed, update the frame and reassign
        if header.frame.size.height != newSize.height {
            var headerFrame = header.frame
            headerFrame.size.height = newSize.height
            header.frame = headerFrame
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Setup: Footer

    private func setupFooter() {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 1))
        footerView.backgroundColor = .clear

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        footerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit

        let footerLabel = UILabel()
        footerLabel.numberOfLines = 0
        footerLabel.lineBreakMode = .byWordWrapping
        footerLabel.textAlignment = .center
        footerLabel.textColor = .secondaryLabel
        footerLabel.font = .preferredFont(forTextStyle: .footnote)
        footerLabel.text =
        """
        \(Content.About.footerAuthors)
        \(Content.About.copyright) © \(Calendar.current.component(.year, from: Date())) \(Content.About.footerCopyright)
        """

        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(footerLabel)

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            stackView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -32)
        ])

        tableView.tableFooterView = footerView
        footerView.setNeedsLayout()
        footerView.layoutIfNeeded()

        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let autoSize = footerView.systemLayoutSizeFitting(targetSize)

        var frame = footerView.frame
        frame.size.height = autoSize.height
        footerView.frame = frame
        tableView.tableFooterView = footerView
    }

    // MARK: - Setup: Sections

    private func setupSections() {
        sections = Config.About.sections.filter { $0.isEnabled }
    }

    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.textProperties.numberOfLines = 0
        content.secondaryTextProperties.numberOfLines = 0

        // Use SF Symbol
        if let icon = item.icon {
            content.image = UIImage(systemName: icon)
            content.imageProperties.tintColor = .label
        }

        // Decide how to display
        switch item {
        case .version:
            cell.selectionStyle = .none
            cell.accessoryType = .none
        default:
            cell.accessoryType = .disclosureIndicator
        }

        // Assign the content
        cell.contentConfiguration = content

        // Make the cells "card-like" in an insetGrouped table:
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.backgroundColor = .secondarySystemBackground
        background.cornerRadius = 8
        background.strokeColor = .clear
        cell.backgroundConfiguration = background

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Hide the title if it's empty
        let title = sections[section].title
        return title.isEmpty ? nil : title
    }

    // MARK: - TableView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .version:
            break
        default:
            delegate?.aboutViewController(self, didSelectItem: item)
        }
    }
}
