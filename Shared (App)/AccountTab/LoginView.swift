//
//  LoginView.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 30.03.26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        Section {
            Text("Sign in to sync your custom bangs across devices.")
                .foregroundColor(.secondary)
        }

        Section {
            Button {
                authManager.login()
            } label: {
                HStack {
                    Image(systemName: "person.badge.key")
                    Text("Continue with GitHub")
                }
            }
            .disabled(authManager.isLoading)
        }

        if authManager.isLoading {
            Section {
                HStack {
                    ProgressView()
                    Text("Signing in...")
                        .padding(.leading, 8)
                }
            }
        }

        if let error = authManager.error {
            Section {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    LoginView()
}
