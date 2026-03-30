//
//  BangListView.swift
//  Shared (App)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import SwiftUI
import Combine

struct BangListView: View {
    
    var showSearch: Bool
    
    @StateObject private var viewModel = BangListViewModel.shared
    @State private var showingAdd = false

    var bangList: some View {
        List {
            Section {
                Toggle(isOn: $viewModel.showCustomOnly) {
                    Text("Show only custom bangs")
                }
                HStack {
                    Text("Bangs")
                    Spacer()
                    Text(viewModel.filteredBangs.count, format: .number)
                        .contentTransition(.numericText(value: Double(viewModel.filteredBangs.count)))
                        .animation(.easeInOut, value: viewModel.filteredBangs.count)
                }
            }
                
            ForEach(viewModel.filteredBangs) { bang in
                NavigationLink {
                    BangDetails(bang: bang, onDelete: {
                        viewModel.loadBangs()
                    })
                } label: {
                    BangRowView(bang: bang)
                }
            }
        }
        .overlay(Group {
            if viewModel.filteredBangs.isEmpty {
                Text(viewModel.searchText.isEmpty ? "No bangs available" : "No results found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        })
        .withSearch(withSearch: showSearch, filter: $viewModel.searchText)
        .navigationTitle("Bangs")
        .toolbar {
            ToolbarItem {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Custom Bang")
            }
        }
        .sheet(isPresented: $showingAdd) {
            BangAddView {
                viewModel.loadBangs()
                showingAdd = false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView("Loading bangs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                bangList
            }
        }
    }
}

#Preview {
    BangListView(showSearch: false)
}

struct WithSearch: ViewModifier {
    let withSearch: Bool
    @Binding var filter: String
    
    func body(content: Content) -> some View {
        if withSearch {
            content
                .searchable(text: $filter, prompt: "Search bangs...")
        } else {
            content
        }
    }
}

extension View {
    func withSearch(withSearch: Bool, filter: Binding<String>) -> some View {
        modifier(WithSearch(withSearch: withSearch, filter: filter))
    }
}
