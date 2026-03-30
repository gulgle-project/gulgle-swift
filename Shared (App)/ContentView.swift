//
//  ContentView.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 30.03.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Bangs", systemImage: "exclamationmark.magnifyingglass") {
                BangListView(showSearch: false)
            }
            
            Tab("Account", systemImage: "person.crop.circle.fill") {
                AccountView()
            }
            
            if #available(iOS 26.0, *) {
                Tab(role: .search) {
                    BangListView(showSearch: true)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
