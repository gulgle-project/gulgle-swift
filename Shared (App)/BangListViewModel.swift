//
//  BangListViewModel.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 28.03.26.
//

import SwiftUI
import Combine

class BangListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var allBangs: [Bang] = []
    @Published var isLoading: Bool = true
    @Published var showCustomOnly: Bool = false

    var filteredBangs: [Bang] {
        var filtered = allBangs
        if showCustomOnly {
            filtered = allBangs.filter { $0.isCustom ?? false }
        }

        guard !searchText.isEmpty else { return filtered }

        let lowercasedSearch = searchText.lowercased()

        if searchText.starts(with: "!") {
            let bangSearch = String(lowercasedSearch.drop(while: { $0 == "!" }))

            if bangSearch.count == 0 {
                return filtered
            }

            return filtered.filter { bang in
                if bang.trigger.starts(with: bangSearch) { return true }
                if let additionalTriggers = bang.additionalTriggers {
                    return additionalTriggers.contains { $0.starts(with: bangSearch) }
                }

                return false
            }
        }

        return filtered.filter { bang in
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
            let bangs = BangRepository.shared.allBangs()

            DispatchQueue.main.async {
                self.allBangs = bangs
                self.isLoading = false
            }
        }
    }
}
