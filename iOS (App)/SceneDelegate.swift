//
//  SceneDelegate.swift
//  iOS (App)
//
//  Created by Wolfgang Schwendtbauer on 22.10.25.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let contentView = BangListView()
        let hostingController = UIHostingController(rootView: contentView)

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
    }

}
