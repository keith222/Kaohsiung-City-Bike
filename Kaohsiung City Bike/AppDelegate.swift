//
//  AppDelegate.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/10/28.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseInstanceID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    var window: UIWindow?
    var mDelegate: sendData?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        UIApplication.shared.statusBarStyle = .lightContent
        UINavigationBar.appearance().barTintColor = UIColor(red: 23.0/255.0, green: 169.0/255.0, blue: 174.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        
        if(UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:)))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert,.sound,.badge], categories: nil))
        }
        
        let notificationType: UIUserNotificationType = [.alert,.sound]
        let notificationSettings = UIUserNotificationSettings(types: notificationType, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        FIRApp.configure()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.prod)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        application.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0
        print(userInfo)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let navigatorController: UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        if url.query!.removingPercentEncoding == "openlist" {
            let viewController = storyboard.instantiateViewController(withIdentifier: "Station") as! StationTableViewController
            navigatorController.viewControllers = [viewController]
            self.window?.rootViewController = navigatorController
            
        }else{
            let viewController = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
            navigatorController.viewControllers = [viewController]
            self.window?.rootViewController = navigatorController
            
            let triggerTime = (Int64(NSEC_PER_SEC)*1)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
                viewController.sendData(url.query!.removingPercentEncoding!)
            })
        }
        return true
    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//        print(url)
//        print(sourceApplication)
//        if sourceApplication == "Sparkrs.CityBike.Kaohsiung-CityBike-Widget"{
//            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let navigatorController: UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
//            print(url.query!.removingPercentEncoding)
//            
//            if url.query!.removingPercentEncoding == "openlist" {
//                let viewController = storyboard.instantiateViewController(withIdentifier: "Station") as! StationTableViewController
//                navigatorController.viewControllers = [viewController]
//                self.window?.rootViewController = navigatorController
//                
//            }else{
//                let viewController = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
//                navigatorController.viewControllers = [viewController]
//                self.window?.rootViewController = navigatorController
//                
//                let triggerTime = (Int64(NSEC_PER_SEC)*1)
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
//                    viewController.sendData(url.query!.removingPercentEncoding!)
//                })
//            }
//            return true
//        }else{
//            return false
//        }
//    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        let viewController = (window?.rootViewController as? UINavigationController)?.viewControllers[0] as! ViewController
        print(userActivity.userInfo ?? "no anything")
        viewController.restoreUserActivityState(userActivity)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

