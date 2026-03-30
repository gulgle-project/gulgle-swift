//
//  BangUsageRepository.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 28.03.26.
//

import Foundation
import os.log

struct BangUsageEntry: Codable {
    var count: Int
    var lastUsed: Date
}

class BangUsageRepository {
    static let shared = BangUsageRepository()

    private let appGroupID = "group.gulgle"
    private let fileName = "BangUsage.json"
    private let queue = DispatchQueue(label: "link.gulgle.Gulgle.BangUsage")

    private init() {}

    /// Record a single usage of a bang by its unique ID.
    func recordUsage(bangID: String) {
        queue.sync {
            var usage = loadUsageUnsafe()
            var entry = usage[bangID] ?? BangUsageEntry(count: 0, lastUsed: Date())
            entry.count += 1
            entry.lastUsed = Date()
            usage[bangID] = entry
            saveUsage(usage)
        }
    }

    /// Load the full usage dictionary.
    func loadUsage() -> [String: BangUsageEntry] {
        return queue.sync { loadUsageUnsafe() }
    }

    /// Convenience: look up usage for a single bang by its unique ID.
    func usage(for bangID: String) -> BangUsageEntry? {
        return loadUsage()[bangID]
    }

    // MARK: - Private

    /// Non-thread-safe load — must be called within `queue.sync`.
    private func loadUsageUnsafe() -> [String: BangUsageEntry] {
        guard let url = usageFileURL(),
              let data = try? Data(contentsOf: url),
              !data.isEmpty
        else { return [:] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([String: BangUsageEntry].self, from: data)
        } catch {
            os_log(.error, "Unable to decode bang usage data!")
            return [:]
        }
    }

    private func saveUsage(_ usage: [String: BangUsageEntry]) {
        guard let url = usageFileURL() else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(usage)
            try data.write(to: url, options: [.atomic])
        } catch {
            os_log(.error, "Error saving bang usage data!")
        }
    }

    private func usageFileURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        return containerURL.appendingPathComponent(fileName, isDirectory: false)
    }
}
