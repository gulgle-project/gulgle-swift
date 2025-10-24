//
//  SearchEngineDetector.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import Foundation

enum SearchEngine {
    case google
    case duckduckgo
    case bing
    case yahoo
    case ecosia
    case startpage
    case unknown
}

struct SearchEngineDetector {

    static func detectEngine(from url: URL) -> SearchEngine? {
        guard let host = url.host?.lowercased() else { return nil }

        if host.contains("google.") {
            return .google
        } else if host.contains("duckduckgo.com") {
            return .duckduckgo
        } else if host.contains("bing.com") {
            return .bing
        } else if host.contains("yahoo.com") || host.contains("search.yahoo.") {
            return .yahoo
        } else if host.contains("ecosia.org") {
            return .ecosia
        } else if host.contains("startpage.com") {
            return .startpage
        }

        return nil
    }

    static func extractQuery(from url: URL, engine: SearchEngine) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        let queryParam: String
        switch engine {
        case .google:
            queryParam = "q"
        case .duckduckgo:
            queryParam = "q"
        case .bing:
            queryParam = "q"
        case .yahoo:
            queryParam = "p"
        case .ecosia:
            queryParam = "q"
        case .startpage:
            queryParam = "query"
        case .unknown:
            return nil
        }

        return queryItems.first(where: { $0.name == queryParam })?.value
    }

    static func isSafariSearch(url: URL, engine: SearchEngine) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        switch engine {
        case .google:
            return components.queryItems?.contains(where: { $0.name == "client" && $0.value == "safari" }) ?? false
        case .duckduckgo:
            return components.queryItems?.contains(where: { $0.name == "t" && $0.value == "safari" }) ?? false
        case .bing:
            return components.queryItems?.contains(where: { $0.name == "PC" && $0.value == "APPL" }) ?? false
        default:
            return true
        }
    }
}
