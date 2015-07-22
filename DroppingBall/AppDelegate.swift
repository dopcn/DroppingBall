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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            window!.rootViewController = ViewController()
        } else {
            window!.rootViewController = ViewControllerHD()
        }
        window!.makeKeyAndVisible()
        
        return true
    }
}