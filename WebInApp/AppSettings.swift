//
//  AppSettings.swift
//  WebInApp
//
//  Created by Alberto Sarmiento on 7/7/18.
//  Copyright © 2018 Alberto Sarmiento. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON
import Haneke


class AppSettingsData
{
	var rawJson = ""
	var version = 0
	var menuItems = [AppSettingsMenuItem]()
	var deniedHosts = [String]()
}

class AppSettingsMenuItem
{
	var title = ""
	var image: UIImage?
	var urlToNav: URL!
	
	fileprivate var fetcher: NetworkFetcher<UIImage>?
}

class AppSettings
{
	static let NewLoadedSettingsNotification = Notification.Name(rawValue: "NewLoadedSettings")
	
	private static var lastSettings = AppSettingsData()
	static var shared: AppSettingsData {
		get {
			reloadRemoteSettingsIfNeeded()
			return lastSettings
		}
	}

	private static var loading = false
	private static var lastSettingsJson = ""
	private static var lastAccessDate = Date()
	private static var autoReloadDelayTimer: Timer?
	
	public static func forceReload()
	{
		if loading { return }
		lastSettingsJson = ""
		reloadRemoteSettingsIfNeeded()
	}
	
	@objc private static func reloadRemoteSettingsIfNeeded()
	{
		if loading { return }
		let elapsedTime = Date().timeIntervalSince(lastAccessDate)
		if elapsedTime > APP_SETTINGS_LOAD_INTERVAL || lastSettingsJson.isEmpty
		{
			loading = true
			autoReloadDelayTimer?.invalidate()
			firstly {
				Alamofire
					.request(APP_SETTINGS_URL, method: .get)
					.responseString()
				}
				.then {
					deserializeSettingsJson(fromString: $0.string)
				}
				.done {
					if !$0.isValid() ||
						!lastSettingsJson.isEmpty && lastSettingsJson == $0.rawJson { return }
					lastSettingsJson = $0.rawJson
					lastSettings = $0
					NotificationCenter.default.post(name: AppSettings.NewLoadedSettingsNotification, object: nil)
				}
				.ensure {
					loading = false
					lastAccessDate = Date()
					autoReloadDelayTimer = Timer
											.scheduledTimer(
												timeInterval: 60.0,
												target: self, selector: #selector(reloadRemoteSettingsIfNeeded),
												userInfo: nil, repeats: false)
				}
				.catch { error in
					print(error)
				}

		}
	}

	private static func deserializeSettingsJson(fromString s: String) -> Promise<AppSettingsData>
	{
		let jS = JSON(parseJSON: s.trimmed.lowercased())
		let miPromises = jS["menu_items"].arrayValue.map {
			AppSettingsMenuItem
				.Create(with: $0["title"].stringValue, imageName: $0["image_name"].stringValue, urlStringToNav: $0["url_to_nav"].stringValue)
		}
		return when(resolved: miPromises)
				.compactMapValues {
					guard case .fulfilled(let mi) = $0 else { return nil }
					return mi
				}
				.map {
					AppSettingsData(
						withRawJson: jS.rawString(options: .sortedKeys)?.trimmed.lowercased() ?? "",
						version: jS["version"].intValue,
						menuItems: $0,
						deniedHosts: jS["denied_hosts"].arrayValue.map { $0.stringValue })
				}
	}
}


public enum AppSettingsLoadError: Error {
	case invalidDefinition
	case menuItemImageFetchingFailed(error: Error?)
	case loadingCanceled
}

extension AppSettingsData
{
	convenience init(withRawJson rawJson: String, version: Int, menuItems: [AppSettingsMenuItem], deniedHosts: [String])
	{
		self.init()
		self.rawJson = rawJson
		self.version = version
		self.menuItems = menuItems
		self.deniedHosts = deniedHosts
	}
	
	func isValid() -> Bool
	{
		return !rawJson.isEmpty
				&& version > 0
			   	//&& menuItems.count > 0
	}
}

extension AppSettingsMenuItem
{
	static func Create(with title: String, imageName: String, urlStringToNav: String) -> Promise<AppSettingsMenuItem>
	{
		let pending = Promise<AppSettingsMenuItem>.pending()
		guard !title.trimmed.isEmpty, !imageName.trimmed.isEmpty, !urlStringToNav.trimmed.isEmpty,
			let imageUrl = URL(string: "\(APP_MENU_IMG_BASEURL)\(imageName)"),
			let urlToNav = URL(string: urlStringToNav)
			else {
				pending.resolver.reject(AppSettingsLoadError.invalidDefinition)
				return pending.promise
		}
		let mi = AppSettingsMenuItem()
		mi.fetcher = NetworkFetcher<UIImage>(URL: imageUrl)
		mi.fetcher?.fetch(
				failure: { error in
					mi.fetcher = nil
					pending.resolver.reject(AppSettingsLoadError.menuItemImageFetchingFailed(error: error))
				},
				success: { img in
					mi.title = title
					mi.urlToNav = urlToNav
					mi.image = img
					mi.fetcher = nil
					pending.resolver.fulfill(mi)
				})
		return pending.promise
	}
}
