//
//  AuthManager.swift
//  Gulgle
//
//  Created for Gulgle auth functionality.
//

import AuthenticationServices
import Foundation
import os.log
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var user: UserDTO?
    @Published var isLoading = false
    @Published var error: String?

    private let authURL = "https://sync.gulgle.link/api/auth/github?platform=ios"
    private let callbackScheme = "gulgle"

    private init() {
        restoreSession()
    }

    // MARK: - Login

    func login() {
        guard let url = URL(string: authURL) else { return }

        isLoading = true
        error = nil

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, authError in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                if let authError = authError {
                    // User cancelled is not an error we should display
                    if (authError as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return
                    }
                    self.error = authError.localizedDescription
                    return
                }

                guard let callbackURL = callbackURL else {
                    self.error = "No callback URL received."
                    return
                }

                await self.handleCallback(callbackURL)
            }
        }

        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = ASWebAuthPresentationContext.shared

        session.start()
    }

    // MARK: - Logout

    func logout() {
        KeychainHelper.deleteToken()
        isAuthenticated = false
        user = nil
        error = nil
    }

    // MARK: - Session Restoration

    func restoreSession() {
        guard let token = KeychainHelper.getToken(),
              KeychainHelper.isTokenValid(token) else {
            logout()
            return
        }

        isAuthenticated = true

        // Fetch user profile in the background
        Task {
            do {
                let userDTO = try await APIClient.shared.getCurrentUser()
                self.user = userDTO
            } catch {
                os_log(.error, "Failed to restore user profile: %{public}@", error.localizedDescription)
                // Token might be invalid server-side
                if case APIError.unauthorized = error {
                    logout()
                }
            }
        }
    }

    // MARK: - Private

    private func handleCallback(_ url: URL) async {
        // The callback URL looks like: gulgle://auth/callback#token=JWT
        // URL.fragment gives us "token=JWT"
        guard let fragment = url.fragment,
              let tokenParam = URLComponents(string: "?\(fragment)")?.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenParam.value else {
            error = "Could not extract token from callback."
            return
        }

        guard KeychainHelper.isTokenValid(token) else {
            error = "Received an expired token."
            return
        }

        KeychainHelper.saveToken(token)
        isAuthenticated = true

        // Fetch user profile
        do {
            let userDTO = try await APIClient.shared.getCurrentUser()
            self.user = userDTO
        } catch {
            os_log(.error, "Failed to fetch user after login: %{public}@", error.localizedDescription)
            self.error = "Signed in, but failed to load profile."
        }
    }
}

// MARK: - ASWebAuthenticationSession Presentation Context

class ASWebAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = ASWebAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
        #else
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #endif
    }
}
