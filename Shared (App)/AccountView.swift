//
//  AccountView.swift
//  Gulgle
//
//  Created for Gulgle auth functionality.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss

    var onSyncComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    loggedInContent
                } else {
                    loggedOutContent
                }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton { dismiss() }
                }
            }
        }
    }

    // MARK: - Logged Out

    @ViewBuilder
    private var loggedOutContent: some View {
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

    // MARK: - Logged In

    @ViewBuilder
    private var loggedInContent: some View {
        Section(header: Text("Profile")) {
            if let user = authManager.user {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(user.displayName)
                        .foregroundColor(.secondary)
                }
                if let email = user.email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading profile...")
                        .padding(.leading, 8)
                }
            }
        }

        Section(header: Text("Sync")) {
            syncStatusRow

            Button {
                Task {
                    await syncManager.fullSync()
                    onSyncComplete?()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Sync Now")
                }
            }
            .disabled(syncManager.status.isSyncing)

            Button {
                Task {
                    await syncManager.syncToCloud()
                    onSyncComplete?()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.to.line")
                    Text("Push to Cloud")
                }
            }
            .disabled(syncManager.status.isSyncing)

            Button {
                Task {
                    await syncManager.syncFromCloud()
                    onSyncComplete?()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.to.line")
                    Text("Pull from Cloud")
                }
            }
            .disabled(syncManager.status.isSyncing)
        }

        // Conflict resolution
        if case .conflict(let serverBangs) = syncManager.status {
            Section(header: Text("Conflict")) {
                Text("The server has different custom bangs than your device. Which version would you like to keep?")
                    .foregroundColor(.orange)
                    .font(.footnote)

                Text("Server has \(serverBangs.count) custom bang(s), device has \(BangRepository.shared.loadCustomBangs().count).")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button {
                    Task {
                        await syncManager.resolveConflict(keepLocal: true)
                        onSyncComplete?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "iphone")
                        Text("Keep Device Version")
                    }
                }

                Button {
                    Task {
                        await syncManager.resolveConflict(keepLocal: false)
                        onSyncComplete?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "cloud")
                        Text("Use Server Version")
                    }
                }
            }
        }

        Section {
            Button(role: .destructive) {
                authManager.logout()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                    Text("Sign Out")
                }
            }
        }
    }

    // MARK: - Sync Status Row

    @ViewBuilder
    private var syncStatusRow: some View {
        HStack {
            Text("Status")
            Spacer()
            switch syncManager.status {
            case .idle:
                Text("Idle")
                    .foregroundColor(.secondary)
            case .syncing:
                HStack(spacing: 6) {
                    ProgressView()
                        #if os(iOS)
                        .controlSize(.small)
                        #endif
                    Text("Syncing...")
                }
                .foregroundColor(.secondary)
            case .success:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Synced")
                        .foregroundColor(.green)
                }
            case .error(let message):
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(message)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .lineLimit(2)
                }
            case .conflict:
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Conflict")
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
