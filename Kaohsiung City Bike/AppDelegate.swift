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
import UserNotifications
import Fabric
import Crashlytics
import SwifterSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        //UINavigationBar.appearance().barTintColor = UIColor(hexString: "#17A9AE")
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        if #available(iOS 11.0, *) {
            UISearchBar.appearance().tintColor = .white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .lightGray
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        }

        //if there is not json file in document, copy it from bundle to document
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let versionPath = doc.appendingPathComponent("version.json").path
        let infoPath = doc.appendingPathComponent("citybike.json").path
        if !FileManager.default.fileExists(atPath: versionPath) {
            do{
                let versionBundlePath = Bundle.main.path(forResource: "version", ofType: "json")
                try FileManager.default.copyItem(atPath: versionBundlePath!, toPath: versionPath)
                
                let infoBundlePath = Bundle.main.path(forResource: "citybike", ofType: "json")
                try FileManager.default.copyItem(atPath: infoBundlePath!, toPath: infoPath)
                
            }catch{
                print(error)
            }
        }
        
        

        let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
        if !userDefault.bool(forKey: "updateStorage") {
            var todayWidgetArray = userDefault.array(forKey: "staForTodayWidget")
            
            var homeViewModel: HomeViewModel? = HomeViewModel()
            homeViewModel?.fetchStationList(handler: { stations in
                for station in stations {
                    let index = todayWidgetArray?.index(where: {
                        print($0)
                        print(station.name)
                        return ($0 as! String) == station.name
                    })
                    guard let _ = index else { continue }
                    todayWidgetArray?[index!] = station.no
                }
            })
            userDefault.set(todayWidgetArray, forKey: "staForTodayWidget")
            userDefault.set(true, forKey: "updateStorage")
            userDefault.synchronize()
            homeViewModel = nil
        }
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Fabric
        Fabric.with([Crashlytics.self])
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        application.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0
        print(userInfo)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let navigatorController: UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        if url.query!.removingPercentEncoding == "openlist" {
            let viewController = storyboard.instantiateViewController(withIdentifier: "Station") as! StationViewController
            navigatorController.viewControllers = [viewController]
            self.window?.rootViewController = navigatorController
            
        }else{
            let viewController = storyboard.instantiateViewController(withIdentifier: "Map") as! HomeViewController
            navigatorController.viewControllers = [viewController]
            self.window?.rootViewController = navigatorController
            
            let triggerTime = (Int64(NSEC_PER_SEC)*1)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
                viewController.setMap()
                viewController.didSelect(url.query!.removingPercentEncoding!)
            })
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let viewController = (window?.rootViewController as? UINavigationController)?.viewControllers[0] as! HomeViewController
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

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        print("%@", userInfo)
        
    }
    
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

