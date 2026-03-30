//
//  SyncView.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 30.03.26.
//

import SwiftUI

struct SyncView: View {
    @ObservedObject private var bangViewModel = BangListViewModel.shared
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var syncManager = SyncManager.shared
    
    var body: some View {
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
            Button {
                Task {
                    await syncManager.fullSync()
                    bangViewModel.loadBangs()
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
                    bangViewModel.loadBangs()
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
                    bangViewModel.loadBangs()
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
                        bangViewModel.loadBangs()
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
                        bangViewModel.loadBangs()
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
}

#Preview {
    SyncView()
}
