//
//  AppDelegate.swift
//  SwiftStitch
//
//  Created by Foundry on 04/06/2014.
//  Copyright (c) 2014 Foundry. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = SwViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}


