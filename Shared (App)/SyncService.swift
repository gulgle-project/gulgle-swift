//
//  SyncService.swift
//  Gulgle
//
//  Created by Assistant on 05.11.25.
//

import Foundation

struct UserDTO: Decodable {
    let email: String
}

enum SyncError: Error, LocalizedError {
    case notImplemented
    case notAuthenticated
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Sync endpoint is not implemented on the server yet."
        case .notAuthenticated:
            return "You must be signed in to sync."
        case .decodingError:
            return "Failed to decode server response."
        }
    }
}

final class SyncService {
    static let shared = SyncService()

    private init() {}

    var isAuthenticated: Bool {
        AuthManager.shared.isAuthenticated
    }

    func currentUser() async throws -> UserDTO {
        // When your /api/user/v1.0/current is live, uncomment:
        // return try await APIClient.shared.get("/api/user/v1.0/current", as: UserDTO.self)
        throw SyncError.notImplemented
    }

    func pull() async throws {
        guard isAuthenticated else { throw SyncError.notAuthenticated }
        // When your settings endpoint is ready:
        // let remote: [Bang] = try await APIClient.shared.get("/api/settings/v1.0", as: [Bang].self)
        // // Ensure custom flag is set for local storage
        // let customs = remote.map { bang in
        //     Bang(trigger: bang.trigger, name: bang.name, category: bang.category, subCategory: bang.subCategory, urlTemplate: bang.urlTemplate, domain: bang.domain, additionalTriggers: bang.additionalTriggers, isCustom: true)
        // }
        // BangRepository.shared.saveCustomBangs(customs)
        throw SyncError.notImplemented
    }

    func push() async throws {
        guard isAuthenticated else { throw SyncError.notAuthenticated }
        // let customs = BangRepository.shared.loadCustomBangs()
        // try await APIClient.shared.put("/api/settings/v1.0", body: customs)
        throw SyncError.notImplemented
    }
}

