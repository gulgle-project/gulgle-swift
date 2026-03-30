//
//  AccountView.swift
//  Gulgle
//
//  Created for Gulgle auth functionality.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var syncManager = SyncManager.shared

    private var showSyncBubble: Bool {
        syncManager.status.isSyncing || syncManager.status.isSuccess
    }

    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    SyncView()
                } else {
                    LoginView()
                }
            }
            .navigationTitle("Account")
            .overlay(alignment: .bottom) {
                if showSyncBubble {
                    SyncBubble(status: syncManager.status)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSyncBubble)
        }
    }
}

#Preview {
    AccountView()
}
