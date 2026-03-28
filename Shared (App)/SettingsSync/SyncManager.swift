//
//  SyncManager.swift
//  Gulgle
//
//  Created for Gulgle sync functionality.
//

import Foundation
import os.log
import Combine

enum SyncStatus {
    case idle
    case syncing
    case success
    case error(String)
    case conflict(serverBangs: [Bang])

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var status: SyncStatus = .idle

    private let lastSyncKey = "LastSyncDate"
    private let appGroupID = "group.gulgle"

    private init() {}

    // MARK: - Sync Operations

    /// Push local custom bangs to the server.
    func syncToCloud() async {
        guard AuthManager.shared.isAuthenticated else {
            status = .error("Not signed in.")
            return
        }

        status = .syncing

        let customBangs = BangRepository.shared.loadCustomBangs()
        let settings = SettingsDTO(
            customBangs: customBangs,
            defaultBang: nil,
            lastModified: Date()
        )

        do {
            let result = try await APIClient.shared.pushSettings(settings)
            saveLastSyncDate(result.lastModified)
            status = .success
            resetStatusAfterDelay()
        } catch let error as APIError {
            if case .conflict = error {
                // Pull server data for conflict resolution
                await handleConflict()
            } else if case .unauthorized = error {
                AuthManager.shared.logout()
                status = .error("Session expired. Please sign in again.")
            } else {
                status = .error(error.localizedDescription)
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Pull settings from the server and overwrite local custom bangs.
    func syncFromCloud() async {
        guard AuthManager.shared.isAuthenticated else {
            status = .error("Not signed in.")
            return
        }

        status = .syncing

        do {
            let serverSettings = try await APIClient.shared.pullSettings()
            applyServerSettings(serverSettings)
            status = .success
            resetStatusAfterDelay()
        } catch let error as APIError {
            if case .unauthorized = error {
                AuthManager.shared.logout()
                status = .error("Session expired. Please sign in again.")
            } else {
                status = .error(error.localizedDescription)
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Bidirectional sync: pull first, compare timestamps, then push or pull.
    func fullSync() async {
        guard AuthManager.shared.isAuthenticated else {
            status = .error("Not signed in.")
            return
        }

        status = .syncing

        do {
            let serverSettings = try await APIClient.shared.pullSettings()
            let lastSync = getLastSyncDate()

            if let lastSync = lastSync, serverSettings.lastModified > lastSync {
                // Server is newer, apply server data
                applyServerSettings(serverSettings)
                status = .success
            } else {
                // Local is newer or first sync, push local
                let customBangs = BangRepository.shared.loadCustomBangs()
                let settings = SettingsDTO(
                    customBangs: customBangs,
                    defaultBang: nil,
                    lastModified: Date()
                )
                let result = try await APIClient.shared.pushSettings(settings)
                saveLastSyncDate(result.lastModified)
                status = .success
            }
            resetStatusAfterDelay()
        } catch let error as APIError {
            if case .conflict = error {
                await handleConflict()
            } else if case .unauthorized = error {
                AuthManager.shared.logout()
                status = .error("Session expired. Please sign in again.")
            } else {
                status = .error(error.localizedDescription)
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    // MARK: - Conflict Resolution

    /// Resolve a conflict by choosing local or server data.
    func resolveConflict(keepLocal: Bool) async {
        if keepLocal {
            // Force push local with a fresh timestamp (will be newer than server)
            let customBangs = BangRepository.shared.loadCustomBangs()
            let settings = SettingsDTO(
                customBangs: customBangs,
                defaultBang: nil,
                lastModified: Date()
            )

            status = .syncing
            do {
                let result = try await APIClient.shared.pushSettings(settings)
                saveLastSyncDate(result.lastModified)
                status = .success
                resetStatusAfterDelay()
            } catch {
                status = .error(error.localizedDescription)
            }
        } else {
            // Pull and apply server data
            await syncFromCloud()
        }
    }

    // MARK: - Private

    private func handleConflict() async {
        do {
            let serverSettings = try await APIClient.shared.pullSettings()
            status = .conflict(serverBangs: serverSettings.customBangs)
        } catch {
            status = .error("Conflict detected, but failed to load server data.")
        }
    }

    private func applyServerSettings(_ settings: SettingsDTO) {
        BangRepository.shared.saveCustomBangs(settings.customBangs)
        saveLastSyncDate(settings.lastModified)
    }

    private func saveLastSyncDate(_ date: Date) {
        sharedDefaults()?.set(date, forKey: lastSyncKey)
    }

    private func getLastSyncDate() -> Date? {
        sharedDefaults()?.object(forKey: lastSyncKey) as? Date
    }

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private func resetStatusAfterDelay() {
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if case .success = status {
                status = .idle
            }
        }
    }
}
