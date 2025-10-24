//
//  BangRepository.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import Foundation

class BangRepository {
    static let shared = BangRepository()

    private init() {}

    func loadBangs() -> [Bang] {
        guard let url = Bundle.main.url(forResource: "bangs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bangs = try? JSONDecoder().decode([Bang].self, from: data) else {
            return []
        }
        return bangs
    }

    func updateBangs(_ bangs: [Bang]) {

    }
}
