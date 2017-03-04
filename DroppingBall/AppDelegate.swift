//
//  AppDelegate.swift
//  DroppingBall
//
//  Created by weizhou on 7/18/15.
//  Copyright (c) 2015 weizhou. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        if UIDevice.current.userInterfaceIdiom == .phone {
            window!.rootViewController = ViewController()
        } else {
            window!.rootViewController = ViewControllerHD()
        }
        window!.makeKeyAndVisible()
        
        return true
    }
}
