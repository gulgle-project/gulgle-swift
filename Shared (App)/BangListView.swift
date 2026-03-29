//
//  BangListView.swift
//  Shared (App)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import SwiftUI
import Combine

struct BangListView: View {
    @StateObject private var viewModel = BangListViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var syncManager = SyncManager.shared
    @State private var showingAdd = false
    @State private var showingAccount = false

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading bangs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            Toggle(isOn: $viewModel.showCustomOnly) {
                                Text("Show only custom bangs")
                            }
                            if #available(iOS 17.0, *) {
                                HStack {
                                    Text("Bangs")
                                    Spacer()
                                    Text(viewModel.filteredBangs.count, format: .number)
                                        .contentTransition(.numericText(value: Double(viewModel.filteredBangs.count)))
                                        .animation(.easeInOut, value: viewModel.filteredBangs.count)
                                }
                            } else {
                                HStack {
                                    Text("Bangs")
                                    Spacer()
                                    Text(viewModel.filteredBangs.count, format: .number)
                                }
                            }
                        }
                            
                        ForEach(viewModel.filteredBangs) { bangItem in
                            NavigationLink {
                                BangDetails(bang: bangItem.bang, onDelete: {
                                    viewModel.loadBangs()
                                })
                            } label: {
                                BangRowView(bang: bangItem.bang)
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Search bangs...")
                    .overlay(Group {
                        if viewModel.filteredBangs.isEmpty {
                            Text(viewModel.searchText.isEmpty ? "No bangs available" : "No results found")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    })
                }
            }
            .navigationTitle("Bangs")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAccount = true
                    } label: {
                        Image(systemName: authManager.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                    }
                    .help("Account")
                }
                #else
                ToolbarItem {
                    Button {
                        showingAccount = true
                    } label: {
                        Image(systemName: authManager.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                    }
                    .help("Account")
                }
                #endif
                ToolbarItem {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add Custom Bang")
                }
            }
        }
        .onAppear {
            viewModel.loadBangs()
        }
        .sheet(isPresented: $showingAdd) {
            BangAddView {
                viewModel.loadBangs()
                showingAdd = false
            }
        }
        .sheet(isPresented: $showingAccount) {
            AccountView(
                authManager: authManager,
                syncManager: syncManager,
                onSyncComplete: {
                    viewModel.loadBangs()
                }
            )
        }
    }
}

#Preview {
    BangListView()
}
