//
//  CarPlaySceneDelegate.swift
//  SwiftRadio
//

import CarPlay
import FRadioPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    private var interfaceController: CPInterfaceController?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let templateApplicationScene = scene as? CPTemplateApplicationScene else { return }
        
        // Set up the CarPlay window
        templateApplicationScene.delegate = self
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        print("CarPlay connected")
        self.interfaceController = interfaceController
        
        // Create a simple list template
        let listTemplate = CPListTemplate(title: "Radio Stations", sections: [])
        
        // Set as root template immediately
        interfaceController.setRootTemplate(listTemplate, animated: false)
        
        // Then fetch and update stations
        StationsManager.shared.fetch { [weak self] _ in
            self?.updateStationsList(listTemplate)
        }
        
        // Subscribe to updates
        StationsManager.shared.addObserver(self)
    }
    
    private func updateStationsList(_ template: CPListTemplate) {
        let stations = StationsManager.shared.stations
        print("Setting up stations list with \(stations.count) stations")
        
        let items = stations.map { station -> CPListItem in
            // Create list item with image
            let item = CPListItem(text: station.name, detailText: station.desc)
            
            // Add station image if available
            station.getImage { image in
                item.setImage(image)
            }
            
            // Handle selection
            item.handler = { _, completion in
                print("Selected station: \(station.name)")
                StationsManager.shared.set(station: station)
                FRadioPlayer.shared.play()
                completion()
            }
            
            return item
        }
        
        let section = CPListSection(items: items)
        template.updateSections([section])
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        print("CarPlay disconnected")
        self.interfaceController = nil
        StationsManager.shared.removeObserver(self)
    }
}

// MARK: - StationsManagerObserver

extension CarPlaySceneDelegate: StationsManagerObserver {
    
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        print("Stations updated: \(stations.count) stations")
        if let listTemplate = interfaceController?.rootTemplate as? CPListTemplate {
            DispatchQueue.main.async {
                self.updateStationsList(listTemplate)
            }
        }
    }
    
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        if let station {
            print("Station changed to: \(station.name)")
        }
    }
}
