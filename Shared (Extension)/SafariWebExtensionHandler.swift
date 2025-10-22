//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private lazy var bangParser: BangParser = {
        let bangs = BangRepository.shared.loadBangs()
        os_log(.default, "Loaded %d bangs", bangs.count)
        return BangParser(bangs: bangs)
    }()

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        guard let messageDict = message as? [String: Any],
              let action = messageDict["action"] as? String else {
            sendEchoResponse(message: message, context: context)
            return
        }
        
        switch action {
        case "checkSearchURL":
            handleSearchURL(messageDict: messageDict, context: context)
        default:
            sendEchoResponse(message: message, context: context)
        }
    }
    
    private func handleSearchURL(messageDict: [String: Any], context: NSExtensionContext) {
        guard let urlString = messageDict["url"] as? String,
              let url = URL(string: urlString) else {
            sendResponse(data: ["type": "noRedirect"], context: context)
            return
        }
        
        guard let engine = SearchEngineDetector.detectEngine(from: url),
              SearchEngineDetector.isSafariSearch(url: url, engine: engine),
              let query = SearchEngineDetector.extractQuery(from: url, engine: engine) else {
            sendResponse(data: ["type": "noRedirect"], context: context)
            return
        }
        
        os_log(.default, "Detected search query: %@", query)
        
        if let bangMatch = bangParser.parseBang(from: query) {
            let redirectURL = bangParser.buildRedirectURL(for: bangMatch)
            os_log(.default, "Bang match found: %@ -> %@", bangMatch.matchedTrigger, redirectURL)
            
            sendResponse(data: [
                "type": "redirect",
                "url": redirectURL,
                "bang": bangMatch.matchedTrigger
            ], context: context)
        } else {
            sendResponse(data: ["type": "noRedirect"], context: context)
        }
    }
    
    private func sendResponse(data: [String: Any], context: NSExtensionContext) {
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: data ]
        } else {
            response.userInfo = [ "message": data ]
        }
        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }
    
    private func sendEchoResponse(message: Any?, context: NSExtensionContext) {
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: [ "echo": message ] ]
        } else {
            response.userInfo = [ "message": [ "echo": message ] ]
        }
        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }

}
