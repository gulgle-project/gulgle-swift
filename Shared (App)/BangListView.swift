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

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading bangs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredBangs) { bangItem in
                            BangRowView(bang: bangItem.bang)
                                .contextMenu {
                                    Button("Delete Custom Bang") {
                                        viewModel.deleteIfCustom(bangItem.bang)
                                    }
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
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Custom Bang")
            }
        }
        .onAppear {
            viewModel.loadBangs()
        }
        .sheet(isPresented: $showingAdd) {
            BangAddView {
                showingAdd = false
            }
        }
    }
}

struct BangRowView: View {
    let bang: Bang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("!\(bang.trigger)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                if let additionalTriggers = bang.additionalTriggers, !additionalTriggers.isEmpty {
                    Text("(\(additionalTriggers.map { "!\($0)" }.joined(separator: ", ")))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(bang.domain)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(bang.name)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(bang.urlTemplate)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 4)
    }
}

struct BangItem: Identifiable, Equatable {
    let id = UUID()
    let bang: Bang
}

class BangListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var allBangs: [BangItem] = []
    @Published var isLoading: Bool = true

    var filteredBangs: [BangItem] {
        guard !searchText.isEmpty else { return allBangs }

        let lowercasedSearch = searchText.lowercased()

        if searchText.starts(with: "!") {
            let bangSearch = String(lowercasedSearch.drop(while: { $0 == "!" }))

            if bangSearch.count == 0 {
                return allBangs
            }

            return allBangs.filter { bangItem in
                let bang = bangItem.bang

                if bang.trigger.starts(with: bangSearch) { return true }
                if let additionalTriggers = bang.additionalTriggers {
                    return additionalTriggers.contains { $0.starts(with: bangSearch) }
                }

                return false
            }
        }

        return allBangs.filter { bangItem in
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

    func addCustom(bang: Bang) {
        do {
            try BangRepository.shared.addOrUpdateCustomBang(bang)
            loadBangs()
        } catch {
            // In production, show an alert. For now, just reload to reflect no change.
            loadBangs()
        }
    }

    func deleteIfCustom(_ bang: Bang) {
        // Only delete if it exists in custom store (not built-in).
        let custom = BangRepository.shared.loadCustomBangs()
        if custom.contains(where: { $0.trigger.caseInsensitiveCompare(bang.trigger) == .orderedSame }) {
            BangRepository.shared.deleteCustomBang(withTrigger: bang.trigger)
            loadBangs()
        }
    }
}
