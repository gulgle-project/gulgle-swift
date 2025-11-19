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
    @State private var showingAdd = false

    // Auth + Sync
    @StateObject private var auth = AuthManager.shared
    @State private var isPerformingAuth = false
    @State private var isSyncing = false
    @State private var alertMessage: String?

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
                        }
                        if auth.isAuthenticated {
                            Section {
                                HStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.accentColor)
                                    Text("Signed in")
                                    Spacer()
                                    Button {
                                        Task { await runPull() }
                                    } label: {
                                        Label("Pull", systemImage: "arrow.down.circle")
                                    }
                                    .disabled(isSyncing)
                                    Button {
                                        Task { await runPush() }
                                    } label: {
                                        Label("Push", systemImage: "arrow.up.circle")
                                    }
                                    .disabled(isSyncing)
                                }
                            }
                        }
                        ForEach(viewModel.filteredBangs) { bangItem in
                            NavigationLink {
                                BangDetails(bang: bangItem.bang)
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
            .navigationTitle("Bangs (\(viewModel.filteredBangs.count))")
            .toolbar {
                ToolbarItemGroup {
                    if auth.isAuthenticated {
                        Button(role: .destructive) {
                            auth.logout()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .help("Sign out")
                    } else {
                        Button {
                            Task { await runLogin() }
                        } label: {
                            if isPerformingAuth {
                                ProgressView()
                            } else {
                                Label("Login", systemImage: "person.badge.key")
                            }
                        }
                        .disabled(isPerformingAuth)
                        .help("Sign in with GitHub")
                    }

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
        .alert(item: Binding(
            get: {
                alertMessage.map { AlertItem(message: $0) }
            },
            set: { newValue in
                alertMessage = newValue?.message
            }
        )) { item in
            Alert(title: Text("Info"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Actions

    private func runLogin() async {
        isPerformingAuth = true
        defer { isPerformingAuth = false }
        do {
            try await auth.login()
        } catch let error as AuthManager.AuthError {
            switch error {
            case .cancelled:
                break
            default:
                alertMessage = "Login failed: \(error)"
            }
        } catch {
            alertMessage = "Login failed: \(error.localizedDescription)"
        }
    }

    private func runPull() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await SyncService.shared.pull()
            viewModel.loadBangs()
            alertMessage = "Pulled settings successfully."
        } catch let e as SyncError {
            alertMessage = e.localizedDescription
        } catch {
            alertMessage = "Pull failed: \(error.localizedDescription)"
        }
    }

    private func runPush() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await SyncService.shared.push()
            alertMessage = "Pushed settings successfully."
        } catch let e as SyncError {
            alertMessage = e.localizedDescription
        } catch {
            alertMessage = "Push failed: \(error.localizedDescription)"
        }
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    BangListView()
}

struct BangItem: Identifiable, Equatable {
    let id = UUID()
    let bang: Bang
}

class BangListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var allBangs: [BangItem] = []
    @Published var isLoading: Bool = true
    @Published var showCustomOnly: Bool = false

    var filteredBangs: [BangItem] {
        var filtered = allBangs
        if showCustomOnly {
            filtered = allBangs.filter { $0.bang.isCustom ?? false }
        }

        guard !searchText.isEmpty else { return filtered }

        let lowercasedSearch = searchText.lowercased()

        if searchText.starts(with: "!") {
            let bangSearch = String(lowercasedSearch.drop(while: { $0 == "!" }))

            if bangSearch.count == 0 {
                return filtered
            }

            return filtered.filter { bangItem in
                let bang = bangItem.bang

                if bang.trigger.starts(with: bangSearch) { return true }
                if let additionalTriggers = bang.additionalTriggers {
                    return additionalTriggers.contains { $0.starts(with: bangSearch) }
                }

                return false
            }
        }

        return filtered.filter { bangItem in
            let bang = bangItem.bang

            if bang.trigger.lowercased().contains(lowercasedSearch) { return true }
            if bang.name.lowercased().contains(lowercasedSearch) { return true }
            if bang.domain.lowercased().contains(lowercasedSearch) { return true }

            if let additionalTriggers = bang.additionalTriggers {
                return additionalTriggers.contains { $0.lowercased().contains(lowercasedSearch) }
            }

            return false
        }
    }

    func loadBangs() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let bangs = BangRepository.shared.loadBangs()
            let bangItems = bangs.map { BangItem(bang: $0) }

            DispatchQueue.main.async {
                self.allBangs = bangItems
                self.isLoading = false
            }
        }
    }
}

