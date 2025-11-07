//
//  BangRepository.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import Foundation
import os.log

class BangRepository {
    static let shared = BangRepository()

    private let appGroupID = "group.gulgle"
    private let customFileName = "CustomBangs.json"

    private init() {}

    // Returns built-in + custom (custom overrides on trigger conflict)
    func loadBangs() -> [Bang] {
        let builtIn = loadBuiltInBangs()
        let custom = loadCustomBangs()

        // Build map of triggers -> Bang for built-ins first
        var triggerMap: [String: Bang] = [:]
        func index(_ bang: Bang) {
            for t in bang.allTriggers() {
                triggerMap[t.lowercased()] = bang
            }
        }

        builtIn.forEach(index)
        // Custom overrides built-ins on any trigger collision
        custom.forEach(index)

        // We want unique Bangs by primary trigger. Rebuild by the stored values.
        // Use a set of primary triggers to dedupe.
        var seenPrimary = Set<String>()
        var result: [Bang] = []
        for bang in triggerMap.values {
            if seenPrimary.insert(bang.trigger.lowercased()).inserted {
                result.append(bang)
            }
        }

        // Optionally sort by trigger
        result.sort { $0.trigger.lowercased() < $1.trigger.lowercased() }
        return result
    }

    // Load only custom bangs
    func loadCustomBangs() -> [Bang] {
        guard let url = customBangsURL(),
              let data = try? Data(contentsOf: url),
              !data.isEmpty
        else { return [] }

        do {
            return try JSONDecoder().decode([Bang].self, from: data)
        } catch {
            // If decoding fails, return empty rather than crashing
            os_log(.error, "Unable to decode stored bangs!")
            return []
        }
    }

    // Replace all custom bangs
    func saveCustomBangs(_ bangs: [Bang]) {
        guard let url = customBangsURL() else { return }
        do {
            let data = try JSONEncoder().encode(bangs)
            try data.write(to: url, options: [.atomic])
        } catch {
            os_log(.error, "Error saving custom bang file!")
        }
    }

    // Add new or update existing custom bang by primary trigger (case-insensitive)
    func addOrUpdateCustomBang(_ bang: Bang) throws {
        try validate(bang: bang)

        var custom = loadCustomBangs()
        // Exclude the bang being updated from collision check
        let customExcludingCurrent = custom.filter { $0.trigger.caseInsensitiveCompare(bang.trigger) != .orderedSame }
        // Prevent conflicts with existing custom triggers (including additionalTriggers)
        try ensureNoTriggerCollision(newBang: bang, within: customExcludingCurrent)
        if let idx = custom.firstIndex(where: { $0.trigger.caseInsensitiveCompare(bang.trigger) == .orderedSame }) {
            custom[idx] = bang
        } else {
            custom.append(bang)
        }
        saveCustomBangs(custom)
        bumpVersion()
    }

    // Delete by primary trigger (case-insensitive)
    func deleteCustomBang(withTrigger trigger: String) {
        var custom = loadCustomBangs()
        custom.removeAll { $0.trigger.caseInsensitiveCompare(trigger) == .orderedSame }
        saveCustomBangs(custom)
        bumpVersion()
    }

    // MARK: - Internal

    private func loadBuiltInBangs() -> [Bang] {
        guard let url = Bundle.main.url(forResource: "kagi-bangs", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            os_log(.error, "Did not find data")
            return []
        }

        do {
            return try JSONDecoder().decode([Bang].self, from: data)
        } catch {
            os_log(.error, "Error decoding built-in bangs: \(error)")
            return []
        }
    }

    private func customBangsURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        return containerURL.appendingPathComponent(customFileName, isDirectory: false)
    }

    // MARK: - Validation and collision checks

    private func validate(bang: Bang) throws {
        // Basic validation: non-empty fields and URL template contains a placeholder
        guard !bang.trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidTrigger
        }
        guard !bang.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidName
        }
        guard !bang.domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidDomain
        }
        let template = bang.urlTemplate
        guard template.contains("%s") else {
            throw ValidationError.invalidTemplate
        }
        // Optional: restrict trigger charset to alphanumerics
        let allowed = CharacterSet.alphanumerics
        if bang.trigger.rangeOfCharacter(from: allowed.inverted) != nil {
            throw ValidationError.invalidTriggerCharacters
        }
        if let extras = bang.additionalTriggers {
            for t in extras {
                if t.rangeOfCharacter(from: allowed.inverted) != nil {
                    throw ValidationError.invalidTriggerCharacters
                }
            }
        }
    }

    private func ensureNoTriggerCollision(newBang: Bang, within customs: [Bang]) throws {
        let newTriggers = Set(newBang.allTriggers().map { $0.lowercased() })
        for existing in customs {
            let existingTriggers = Set(existing.allTriggers().map { $0.lowercased() })
            if !newTriggers.isDisjoint(with: existingTriggers) {
                throw ValidationError.triggerCollision
            }
        }
    }

    // Optional: version bump to allow the extension to know changes occurred
    private let versionKey = "CustomBangsVersion"

    private func bumpVersion() {
        guard let defaults = sharedDefaults() else { return }
        let current = defaults.integer(forKey: versionKey)
        defaults.set(current + 1, forKey: versionKey)
    }

    func currentVersion() -> Int {
        sharedDefaults()?.integer(forKey: versionKey) ?? 0
    }

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    enum ValidationError: Error {
        case invalidTrigger
        case invalidName
        case invalidDomain
        case invalidTemplate
        case invalidTriggerCharacters
        case triggerCollision
    }

    // Deprecated: the old updateBangs placeholder (kept to avoid breaking callers)
    func updateBangs(_ bangs: [Bang]) {
        saveCustomBangs(bangs)
        bumpVersion()
    }
}
