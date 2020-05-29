//
//  AppDelegate.swift
//  CoThings
//
//  Created by Neso on 2020/05/01.
//  Copyright © 2020 Rainlab. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		// notificationRequest()

		return true
	}


	func notificationRequest() {
		let notificationCenter = UNUserNotificationCenter.current()
		let options: UNAuthorizationOptions = [.alert, .sound]
		notificationCenter.requestAuthorization(options: options) {
			(didAllow, _) in
			if !didAllow {
				print("User has declined notifications")
			}
		}
		notificationCenter.getNotificationSettings { (settings) in
			if settings.authorizationStatus != .authorized {
				// Notifications not allowed
			}
		}
	}


	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}


extension Bundle {
	var releaseVersionNumber: String? {
		return infoDictionary?["CFBundleShortVersionString"] as? String
	}
	var buildVersionNumber: String? {
		return infoDictionary?["CFBundleVersion"] as? String
	}
	var releaseVersionNumberPretty: String {
		return "v\(releaseVersionNumber ?? "1.0.0")"
	}
}
