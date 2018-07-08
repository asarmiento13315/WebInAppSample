//
//  AppDelegate.swift
//  WebInApp
//
//  Created by Alberto Sarmiento on 7/6/18.
//  Copyright © 2018 Alberto Sarmiento. All rights reserved.
//

import UIKit
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		setupOneSignalConnection(launchOptions)
		
		AppSettings.forceReload()
				
		return true
	}

	
	func setupOneSignalConnection(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
	{
		OneSignal.initWithLaunchOptions(launchOptions, appId: ONE_SIGNAL_APPID,
			handleNotificationAction:
				{ result in
					let payload: OSNotificationPayload? = result?.notification.payload
					
					let fullMessage = payload?.body
					print(fullMessage as Any)
					
					//Try to fetch the action selected
					if let additionalData = payload?.additionalData
					{
						if additionalData.has(key: "reload_settings") {
							let value = additionalData["reload_settings"] as? String ?? ""
							if ["", "yes","true","1"].contains(value.trimmed.lowercased()) {
								AppSettings.forceReload()
							}
						}
						
						if let urlToNav = additionalData["url_to_nav"] as? String {
							print("\nUrl To Nav:\(urlToNav)")
							self.navigationFromPushNotification(urlToNav)
						}
					}
				},
			settings: [kOSSettingsKeyAutoPrompt : true])
	}
	
	static let NavigateToUrlNotification = Notification.Name(rawValue: "NavigateToUrl")
	static let UrlToNavFromNotificationKey = "UrlToNavFromNotificationKey"
	
	func navigationFromPushNotification(_ urlToNav: String)
	{
		NotificationCenter.default.post(name: AppDelegate.NavigateToUrlNotification, object: nil, userInfo: [AppDelegate.UrlToNavFromNotificationKey : urlToNav])
		
//		let alert = UIAlertController(title: "OneSignal!", message: "nav to url: \(urlToNav)", preferredStyle: .alert)
//		alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
//		window?.rootViewController?.present(alert, animated: true, completion: nil)
	}
	
	
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

