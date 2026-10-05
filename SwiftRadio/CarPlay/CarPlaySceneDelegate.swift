//
//  CarPlaySceneDelegate.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 1/25/25.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//
//

import CarPlay
import OSLog
import SwiftRadioCore

/// Bridges CarPlay templates to the same catalog, transport, and artwork used by the phone.
@MainActor final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private let environment = AppEnvironment.shared
    private weak var interfaceController: CPInterfaceController?
    private var listTemplate: CPListTemplate?
    private var observation: CarPlayObservation?
    private var artworkTasks: [Task<Void, Never>] = []
    private var displayedContent: CatalogListContent?
    private var items: [String: CPListItem] = [:]
    private var isPushingNowPlaying = false
    private var generation = 0
    /// Pushed catalog pages by page number, so a new paging can update them in place.
    private var pageTemplates: [Int: WeakListTemplate] = [:]
    /// CarPlay audio apps may stack five templates: four list pages leave room for Now Playing.
    private static let maximumPageCount = 4

    private struct WeakListTemplate {
        weak var template: CPListTemplate?
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? CPTemplateApplicationScene else { return }
        scene.delegate = self
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        disconnect()
        self.interfaceController = interfaceController
        let template = CPListTemplate(title: Content.CarPlay.title, sections: [])
        listTemplate = template
        interfaceController.setRootTemplate(template, animated: false, completion: nil)

        let generation = generation
        let observation = CarPlayObservation(stations: environment.stations, player: environment.player)
        self.observation = observation
        observation.start { [weak self] in
            guard let self, self.generation == generation else { return }
            render()
        }
        if environment.stations.stations.isEmpty, environment.stations.loadState != .loading {
            loadCatalog()
        }
    }

    private func render() {
        guard let template = listTemplate else { return }
        // Some cars cap lists (often at 12 items while driving); the limit can change at runtime.
        let content = CatalogListContent(stations: environment.stations.stations,
                                         loadState: environment.stations.loadState,
                                         maximumItemCount: CPListTemplate.maximumItemCount,
                                         maximumPageCount: Self.maximumPageCount)
        if content != displayedContent {
            artworkTasks.forEach { $0.cancel() }
            artworkTasks.removeAll()
            items.removeAll()
            displayedContent = content
            template.updateSections(sections(for: content))
            // Pushed pages follow the new paging; one that no longer exists is left empty.
            pageTemplates = pageTemplates.filter { $0.value.template != nil }
            for (page, box) in pageTemplates {
                box.template?.updateSections(stationSections(for: content, page: page))
            }
        }
        let currentID = environment.stations.currentStation?.id
        let playing = environment.player.state == .playing
        for (stationID, item) in items {
            item.isPlaying = playing && stationID == currentID
        }
    }

    /// One section at most, which always fits `CPListTemplate.maximumSectionCount`.
    private func sections(for content: CatalogListContent) -> [CPListSection] {
        guard let template = listTemplate else { return [] }
        switch content {
        case .loading:
            // The empty view only shows while the list has no items.
            template.emptyViewTitleVariants = [Content.Stations.loadingMessage]
            template.emptyViewSubtitleVariants = []
            return []
        case .failed(let message):
            // A row rather than the empty view: the driver must be able to recover without the phone.
            return [CPListSection(items: [retryItem(detail: message)], header: Content.Loader.errorTitle,
                                  sectionIndexTitle: nil)]
        case .empty:
            return [CPListSection(items: [retryItem(detail: nil)])]
        case .stations(let pages, let hiddenCount):
            if hiddenCount > 0 {
                Logger(subsystem: "SwiftRadio", category: "CarPlay")
                    .debug("CarPlay list pages hold \(pages.joined().count) stations; \(hiddenCount) not shown")
            }
            return stationSections(for: content, page: 0)
        }
    }

    /// A page's stations, then a More row when a later page exists.
    private func stationSections(for content: CatalogListContent, page: Int) -> [CPListSection] {
        guard case .stations(let pages, _) = content, pages.indices.contains(page) else { return [] }
        var rows = pages[page].map(stationItem)
        if page + 1 < pages.count { rows.append(moreItem(page: page + 1)) }
        return [CPListSection(items: rows)]
    }

    private func moreItem(page: Int) -> CPListItem {
        let generation = generation
        let item = CPListItem(text: Content.CarPlay.more, detailText: nil)
        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            defer { completion() }
            guard let self, self.generation == generation, let interfaceController = self.interfaceController,
                  let content = self.displayedContent else { return }
            let template = CPListTemplate(title: Content.CarPlay.title,
                                          sections: self.stationSections(for: content, page: page))
            self.pageTemplates[page] = WeakListTemplate(template: template)
            interfaceController.pushTemplate(template, animated: true, completion: nil)
        }
        return item
    }

    private func stationItem(_ station: SwiftRadioCore.RadioStation) -> CPListItem {
        let generation = generation
        let item = CPListItem(text: station.name, detailText: station.desc)
        items[station.id] = item
        item.handler = { [weak self] _, completion in
            // CarPlay delivers selection on the main actor; always release its spinner.
            defer { completion() }
            guard let self, self.generation == generation, self.listTemplate != nil,
                  self.environment.stations.stations.contains(station) else { return }
            // Re-tapping the playing or loading station must never restart or cancel it in the car.
            guard self.environment.stations.activate(station, on: .carPlay) != .unavailable else { return }
            self.showNowPlaying()
        }
        artworkTasks.append(Task { [weak self, weak item, artwork = environment.artwork] in
            let image = await artwork.image(for: station)
            guard !Task.isCancelled, let self, let item, self.generation == generation,
                  self.items[station.id] === item else { return }
            item.setImage(image)
        })
        return item
    }

    private func retryItem(detail: String?) -> CPListItem {
        let generation = generation
        let item = CPListItem(text: Content.Loader.retryButton, detailText: detail)
        item.handler = { [weak self] _, completion in
            defer { completion() }
            guard let self, self.generation == generation,
                  self.environment.stations.loadState != .loading else { return }
            self.loadCatalog()
        }
        return item
    }

    private func loadCatalog() {
        // A catalog request belongs to all scenes and must survive CarPlay disconnect.
        Task { [stations = environment.stations] in await stations.load() }
    }

    /// Apple's audio-app flow: a selection lands on Now Playing, and Back returns to the list.
    private func showNowPlaying() {
        guard let interfaceController, !isPushingNowPlaying,
              !(interfaceController.topTemplate is CPNowPlayingTemplate) else { return }
        isPushingNowPlaying = true
        let generation = generation
        interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.isPushingNowPlaying = false
            }
        }
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        disconnect()
    }

    private func disconnect() {
        generation += 1
        observation?.stop()
        observation = nil
        artworkTasks.forEach { $0.cancel() }
        artworkTasks.removeAll()
        items.removeAll()
        pageTemplates.removeAll()
        displayedContent = nil
        isPushingNowPlaying = false
        listTemplate = nil
        interfaceController = nil
    }
}
