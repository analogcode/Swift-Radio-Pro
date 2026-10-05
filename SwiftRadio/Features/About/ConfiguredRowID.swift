//
//  ConfiguredRowID.swift
//  Swift Radio
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

/// Row identity for the configurable About, Features and Libraries lists.
///
/// A fork can list the same title or repository twice. ForEach needs ids that are unique as
/// well as stable, so repeats get an occurrence suffix. The lists come from static
/// configuration and never reorder at runtime, so an occurrence count is stable.
enum ConfiguredRowID {
    static func make(_ keys: [String]) -> [String] {
        var used = Set<String>()
        return keys.map { key in
            var id = key
            var occurrence = 1
            while !used.insert(id).inserted {
                occurrence += 1
                id = "\(key)#\(occurrence)"
            }
            return id
        }
    }
}
