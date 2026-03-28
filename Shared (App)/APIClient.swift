//
//  APIClient.swift
//  Gulgle
//
//  Created for Gulgle sync functionality.
//

import Foundation
import os.log

// MARK: - API Types

struct UserDTO: Codable {
    let displayName: String
    let email: String?
}

struct SettingsDTO: Codable {
    let customBangs: [Bang]
    let defaultBang: Bang?
    let lastModified: Date
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case unauthorized
    case conflict
    case networkError(Error)
    case invalidResponse(Int)
    case decodingError(Error)
    case noToken

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .conflict:
            return "Settings conflict detected."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "Server error (HTTP \(code))."
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .noToken:
            return "Not signed in."
        }
    }
}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://sync.gulgle.link"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    // Token is read from the Keychain via KeychainHelper at call time
    private var token: String? {
        KeychainHelper.getToken()
    }

    // MARK: - User

    func getCurrentUser() async throws -> UserDTO {
        return try await authenticatedRequest(
            path: "/api/user/v1.0/current",
            method: "GET"
        )
    }

    // MARK: - Settings

    func pullSettings() async throws -> SettingsDTO {
        return try await authenticatedRequest(
            path: "/api/settings/v1.0",
            method: "GET"
        )
    }

    func pushSettings(_ settings: SettingsDTO) async throws -> SettingsDTO {
        return try await authenticatedRequest(
            path: "/api/settings/v1.0",
            method: "PUT",
            body: settings
        )
    }

    // MARK: - Private

    private func authenticatedRequest<T: Decodable>(
        path: String,
        method: String,
        body: (some Encodable)? = nil as SettingsDTO?
    ) async throws -> T {
        guard let token = token else {
            throw APIError.noToken
        }

        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.unauthorized
        case 409:
            throw APIError.conflict
        default:
            throw APIError.invalidResponse(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
