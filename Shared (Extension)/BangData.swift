//
//  BangData.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import Foundation

struct Bang: Codable, Equatable {
    let trigger: String
    let name: String
    let category: String?
    let subCategory: String?
    let urlTemplate: String
    let domain: String
    let additionalTriggers: [String]?
    let isCustom: Bool?

    enum CodingKeys: String, CodingKey {
        case trigger = "t"
        case name = "s"
        case category = "c"
        case subCategory = "sc"
        case urlTemplate = "u"
        case domain = "d"
        case additionalTriggers = "ts"
        case isCustom = "ic"
    }

    func allTriggers() -> [String] {
        var triggers = [trigger]
        if let additional = additionalTriggers {
            triggers.append(contentsOf: additional)
        }
        return triggers
    }

    static func == (lhs: Bang, rhs: Bang) -> Bool {
        lhs.trigger == rhs.trigger
    }
}

struct BangMatch {
    let bang: Bang
    let query: String
    let matchedTrigger: String
}

class BangParser {
    private let bangs: [Bang]
    private var triggerMap: [String: Bang] = [:]

    init(bangs: [Bang]) {
        self.bangs = bangs
        buildTriggerMap()
    }

    private func buildTriggerMap() {
        for bang in bangs {
            for trigger in bang.allTriggers() {
                triggerMap[trigger.lowercased()] = bang
            }
        }
    }

    func parseBang(from searchQuery: String) -> BangMatch? {
        let pattern = "!([a-zA-Z0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = searchQuery as NSString
        let matches = regex.matches(in: searchQuery, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if match.numberOfRanges >= 2 {
                let triggerRange = match.range(at: 1)
                let trigger = nsString.substring(with: triggerRange)

                if let bang = triggerMap[trigger.lowercased()] {
                    let fullMatchRange = match.range
                    var query = searchQuery
                    query.removeSubrange(Range(fullMatchRange, in: query)!)
                    query = query.trimmingCharacters(in: .whitespaces)

                    return BangMatch(bang: bang, query: query, matchedTrigger: trigger)
                }
            }
        }

        return nil
    }

    func buildRedirectURL(for match: BangMatch) -> String {
        let encodedQuery = match.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? match.query
        let template = match.bang.urlTemplate
        if template.contains("{{{s}}}") {
            return template.replacingOccurrences(of: "{{{s}}}", with: encodedQuery)
        } else {
            return template.replacingOccurrences(of: "%s", with: encodedQuery)
        }
    }
}
