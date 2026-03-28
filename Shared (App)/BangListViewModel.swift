//
//  BangListViewModel.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 28.03.26.
//

import SwiftUI
import Combine

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
