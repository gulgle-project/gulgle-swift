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
                        Section {
                            Toggle(isOn: $viewModel.showCustomOnly) {
                                Text("Show only custom bangs")
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
                viewModel.loadBangs()
                showingAdd = false
            }
        }
    }
}

#Preview {
    BangListView()
}
