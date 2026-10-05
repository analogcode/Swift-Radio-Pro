//
//  AboutScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Root of the About flow. Owns its own `NavigationStack` inside the sheet,
/// renders `Config.About.sections` (filtered by `isEnabled`) as an
/// inset-grouped list with a markdown header and a logo/author footer,
/// and routes every row action (push, Safari sheet, mail sheet/alert,
/// share, rate, version display).
struct AboutScreen: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var safariURL: URL?
    @State private var mailAddress: String?
    @State private var showMailError = false

    /// Built once: the configuration is static, and ids must not be recomputed per body.
    private static let sections: [AboutSection] = {
        let enabled = Config.About.sections.filter(\.isEnabled)
        return zip(ConfiguredRowID.make(enabled.map(\.title)), enabled).map { id, section in
            AboutSection(id: id, section: section)
        }
    }()

    var body: some View {
        NavigationStack {
            List {
                AboutIntroSection(text: Self.aboutAttributedText)
                ForEach(Self.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            self.row(for: row.item)
                        }
                    } header: {
                        Text(section.title)
                            .textCase(nil)
                    }
                }
                Section {
                    VStack(spacing: 16) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .accessibilityIdentifier("aboutFooterLogo")
                        Text(verbatim: "\(Content.About.footerAuthors)\n\(Self.copyrightNotice)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    // The grouped section already separates the footer from the final row.
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(Text(Content.About.title))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
            .tint(Color(uiColor: Config.tintColor))
            .sheet(isPresented: safariSheetPresented) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
            .sheet(isPresented: mailSheetPresented) {
                if let address = mailAddress {
                    MailComposeView(subject: Config.emailSubject, recipients: [address])
                }
            }
            .alert(Text(Content.Common.couldNotSendEmail), isPresented: $showMailError) {
                Button(Content.Common.ok) {}
            } message: {
                Text(Content.Common.emailErrorMessage)
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: InfoItem) -> some View {
        switch item {
        case .features:
            NavigationLink {
                FeaturesScreen()
            } label: {
                rowLabel(for: item)
            }
        case .libraries:
            NavigationLink {
                LibrariesScreen()
            } label: {
                rowLabel(for: item)
            }
        case .credits(_, _, let owner, let repo, _):
            NavigationLink {
                ContributorsScreen(owner: owner, repo: repo)
            } label: {
                rowLabel(for: item)
            }
        case .link(_, _, let urlString, _):
            Button {
                safariURL = URL(string: urlString)
            } label: {
                rowLabel(for: item)
            }
        case .email(_, _, let address, _):
            Button {
                if MailComposeView.canSendMail {
                    mailAddress = address
                } else {
                    showMailError = true
                }
            } label: {
                rowLabel(for: item)
            }
        case .rateApp(_, let appID, _):
            Button {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") {
                    openURL(url)
                }
            } label: {
                rowLabel(for: item)
            }
        case .share(_, let text, _):
            ShareLink(item: text) {
                rowLabel(for: item)
            }
        case .version:
            rowLabel(for: item)
        }
    }

    /// Icon + title (+ optional subtitle) label shared by all tappable rows.
    private func rowLabel(for item: InfoItem) -> some View {
        HStack(spacing: 16) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if item.showsExplicitDisclosure {
                Spacer(minLength: 8)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Helpers

    /// "Copyright © <current year> <holder>", matching the UIKit footer.
    private static var copyrightNotice: String {
        let year = Calendar.current.component(.year, from: Date())
        return "\(Content.About.copyright) © \(year) \(Content.About.footerCopyright)"
    }

    /// The About header text with `**bold**` markdown markers rendered bold.
    private static var aboutAttributedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: Content.About.headerText, options: options))
            ?? AttributedString(Content.About.headerText)
    }

    /// Bridges the optional `safariURL` state to a `sheet(isPresented:)` binding.
    private var safariSheetPresented: Binding<Bool> {
        Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )
    }

    /// Bridges the optional `mailAddress` state to a `sheet(isPresented:)` binding.
    private var mailSheetPresented: Binding<Bool> {
        Binding(
            get: { mailAddress != nil },
            set: { if !$0 { mailAddress = nil } }
        )
    }
}

private struct AboutIntroSection: View {
    let text: AttributedString

    var body: some View {
        if #available(iOS 26, *) {
            section.listSectionMargins(.horizontal, 16)
        } else {
            section
        }
    }

    private var section: some View {
        Section {
            Text(text)
                .accessibilityIdentifier("aboutIntroduction")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
                .padding(.top, 24)
                // List supplies additional spacing before the first labeled section.
                .padding(.bottom, 8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
}

/// A configured section with ids that stay unique when a fork repeats a title.
private struct AboutSection: Identifiable {
    struct Row: Identifiable {
        let id: String
        let item: InfoItem
    }

    let id: String
    let title: String
    let rows: [Row]

    init(id: String, section: InfoSection) {
        self.id = id
        title = section.title
        rows = zip(ConfiguredRowID.make(section.items.map(\.title)), section.items).map(Row.init)
    }
}

private extension InfoItem {
    /// NavigationLink supplies its own chevron; modal and external actions need one.
    var showsExplicitDisclosure: Bool {
        switch self {
        case .link, .email, .rateApp, .share: true
        case .features, .libraries, .credits, .version: false
        }
    }
}
