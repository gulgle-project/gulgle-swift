//
//  AuthManager.swift
//  Gulgle
//
//  Created by Assistant on 05.11.25.
//

import Foundation
import AuthenticationServices
import Security
import Combine

@MainActor
final class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    // MARK: - Configuration
    private let authBaseURL = URL(string: "https://sync.gulgle.link")!
    private let loginPath = "/api/auth/github"
    private let callbackScheme = "gulgle" // configure in Info.plist URL Types
    private let callbackPath = "/auth/callback" // gulgle://auth/callback?token=...

    // MARK: - Published state
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var token: String? = nil

    private var session: ASWebAuthenticationSession?

    private override init() {
        super.init()
        self.token = KeychainHelper.shared.readToken()
        self.isAuthenticated = (self.token != nil)
    }

    func login() async throws {
        // Build auth URL
        let authURL = authBaseURL.appendingPathComponent(loginPath)

        // ASWebAuthenticationSession will call back to our custom scheme
        let callbackScheme = self.callbackScheme

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                guard let self else {
                    continuation.resume(throwing: AuthError.unknown)
                    return
                }
                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.missingCallbackURL)
                    return
                }

                // Expect gulgle://auth/callback?token=JWT
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                    continuation.resume(throwing: AuthError.invalidCallbackURL)
                    return
                }

                // Optional: verify path
                if components.path != self.callbackPath {
                    // Allow if you only check scheme; otherwise enforce:
                    // continuation.resume(throwing: AuthError.invalidCallbackURL)
                    // return
                }

                let token = components.queryItems?.first(where: { $0.name == "token" })?.value

                guard let token, !token.isEmpty else {
                    continuation.resume(throwing: AuthError.missingToken)
                    return
                }

                KeychainHelper.shared.storeToken(token)
                self.token = token
                self.isAuthenticated = true
                continuation.resume(returning: ())
            }

            // For macOS/iOS presentation
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            self.session = session
            _ = session.start()
        }
    }

    func logout() {
        KeychainHelper.shared.deleteToken()
        token = nil
        isAuthenticated = false
    }

    func authorizedRequest(url: URL, method: String = "GET", body: Data? = nil, contentType: String? = "application/json") throws -> URLRequest {
        guard let token = token else { throw AuthError.notAuthenticated }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let contentType = contentType {
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        req.httpBody = body
        return req
    }

    enum AuthError: Error {
        case notAuthenticated
        case cancelled
        case missingCallbackURL
        case invalidCallbackURL
        case missingToken
        case unknown
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
#if os(macOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
#else
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
#endif
}

// MARK: - Keychain helper

private final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "link.gulgle.sync"
    private let account = "authToken"

    func storeToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        let attrs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemAdd(attrs as CFDictionary, nil)
    }

    func readToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
