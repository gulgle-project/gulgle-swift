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
    
    var body: some View {
        NavigationView {
            VStack {
                #if os(macOS)
                TextField("Search bangs...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                #endif
                
                if viewModel.isLoading {
                    ProgressView("Loading bangs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredBangs.isEmpty {
                    Text(viewModel.searchText.isEmpty ? "No bangs available" : "No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredBangs) { bangItem in
                        BangRowView(bang: bangItem.bang)
                    }
                    #if os(iOS)
                    .searchable(text: $viewModel.searchText, prompt: "Search bangs...")
                    #endif
                }
            }
            .navigationTitle("Bangs (\(viewModel.filteredBangs.count))")
            #if os(macOS)
            .frame(minWidth: 600, minHeight: 400)
            #endif
        }
        .onAppear {
            viewModel.loadBangs()
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
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "bangs", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let bangs = try? JSONDecoder().decode([Bang].self, from: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            let bangItems = bangs.map { BangItem(bang: $0) }
            
            DispatchQueue.main.async {
                self.allBangs = bangItems
                self.isLoading = false
            }
        }
    }
}
