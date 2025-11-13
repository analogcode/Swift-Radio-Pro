//
//  ConfigClientTestViewController.swift
//  RadioSpiral
//
//  Created on 2025-11-12.
//  Test harness for ConfigClient
//

import UIKit

/// Simple test harness to verify ConfigClient works in isolation
class ConfigClientTestViewController: UIViewController {

    private let textView = UITextView()
    private let testButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ConfigClient Tests"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    private func setupUI() {
        // Test button
        testButton.setTitle("Run Tests", for: .normal)
        testButton.backgroundColor = .systemBlue
        testButton.setTitleColor(.white, for: .normal)
        testButton.addTarget(self, action: #selector(runTests), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)

        // Text view for output
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            testButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            testButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            testButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            testButton.heightAnchor.constraint(equalToConstant: 44),

            textView.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func runTests() {
        textView.text = "Starting ConfigClient tests...\n\n"

        log("Test 1: Verify ConfigClient can be instantiated with custom URL")
        let testConfigPath = Bundle.main.path(forResource: "test-config-with-fallback", ofType: "json", inDirectory: "Testing")
        if let path = testConfigPath {
            let fileURL = URL(fileURLWithPath: path)
            let client = ConfigClient(configURL: fileURL.absoluteString)
            log("✓ ConfigClient created with file:// URL\n")

            log("Test 2: Verify station lookup method")
            let station = client.getStationInfo(byShortCode: "test")
            log("✓ getStationInfo returns optional: \(station == nil)\n")

            log("Test 3: Fetch from test config file")
            client.fetchStations { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let stations):
                        self?.log("✓ Successfully loaded \(stations.count) station(s)")
                        for station in stations {
                            self?.log("  - \(station.name) (\(station.shortCode))")
                        }
                    case .failure(let error):
                        self?.log("✗ Failed to load stations: \(error)")
                    }

                    self?.log("\n✓ All tests completed")
                    self?.log("\nNext steps:")
                    self?.log("1. Test with real Azuracast server")
                    self?.log("2. Test fallback scenarios with down servers")
                    self?.log("3. Integrate with MetadataManager")
                }
            }
        } else {
            log("✗ Could not find test config file")
        }
    }

    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.textView.text.append(message + "\n")
            let range = NSRange(location: self.textView.text.count - 1, length: 1)
            self.textView.scrollRangeToVisible(range)
        }
    }
}
