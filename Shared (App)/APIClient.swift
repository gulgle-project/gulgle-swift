//
//  APIClient.swift
//  Gulgle
//
//  Created by Assistant on 05.11.25.
//

import Foundation

struct APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://sync.gulgle.link")!
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let req = try AuthManager.shared.authorizedRequest(url: url, method: "GET", body: nil, contentType: nil)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body, response: T.Type) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let data = try encoder.encode(body)
        let req = try AuthManager.shared.authorizedRequest(url: url, method: "PUT", body: data, contentType: "application/json")
        let (respData, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: respData)
        return try decoder.decode(T.self, from: respData)
    }

    func put<Body: Encodable>(_ path: String, body: Body) async throws {
        let url = baseURL.appendingPathComponent(path)
        let data = try encoder.encode(body)
        let req = try AuthManager.shared.authorizedRequest(url: url, method: "PUT", body: data, contentType: "application/json")
        let (_, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: nil)
    }

    private func validate(_ response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message: String
            if let data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
                message = str
            } else {
                message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }
            throw APIError.httpError(code: http.statusCode, message: message)
        }
    }

    enum APIError: Error, LocalizedError {
        case invalidResponse
        case httpError(code: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response."
            case .httpError(let code, let message):
                return "HTTP \(code): \(message)"
            }
        }
    }
}

