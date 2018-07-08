//
//  MainViewController.swift
//  WebInApp
//
//  Created by Alberto Sarmiento on 7/7/18.
//  Copyright © 2018 Alberto Sarmiento. All rights reserved.
//

import UIKit
import RevealingSplashView
import SwifterSwift
import OneSignal

class MainViewController: UIViewController, UIWebViewDelegate, UITabBarDelegate
{	
	@IBOutlet weak var webView: UIWebView!
	@IBOutlet weak var menuBar: UITabBar!
	@IBOutlet weak var menuBarBottomConstraint: NSLayoutConstraint!
	
	
	let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "logo"), iconInitialSize: CGSize(width: 340, height: 140), backgroundColor: Color(hexString: LOGO_BACK_COLOR)!)
	var notReady = true
	var readyDelayTimer: Timer?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		view.addSubview(revealingSplashView)
		revealingSplashView.animationType = .heartBeat
		revealingSplashView.startAnimation()
		
		menuBar.delegate = self
		webView.delegate = self
		
		setupMenuBar()
		
		let url = URL(string: APP_MAIN_URL)
		webView.loadRequest(URLRequest(url: url!))
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(MainViewController.setupMenuBar),
											   name: AppSettings.NewLoadedSettingsNotification,
											   object: nil)
		NotificationCenter.default.addObserver(self,
											   selector: #selector(MainViewController.NavigateToUrlFromNotification),
											   name: AppDelegate.NavigateToUrlNotification,
											   object: nil)
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self,
												  name: AppSettings.NewLoadedSettingsNotification,
												  object: nil)
		NotificationCenter.default.removeObserver(self,
												  name: AppDelegate.NavigateToUrlNotification,
												  object: nil)
	}
	
	@objc func setupMenuBar()
	{
		guard AppSettings.shared.isValid() else {
			adjustMenuBarVisibility(visible: false)
			return
		}
		OneSignal.sendTags(["settings_version": AppSettings.shared.version])
		
		var items = [UITabBarItem]()
		for (id, mi) in AppSettings.shared.menuItems.enumerated() {
			items.append(UITabBarItem(title: mi.title, image: mi.image?.scaled(toHeight: menuBar.frame.size.height), tag: id))
		}
		menuBar.setItems(items, animated: true)
		adjustMenuBarVisibility(visible: true)
	}

	func adjustMenuBarVisibility(visible: Bool)
	{
		menuBarBottomConstraint.constant = visible ? 0 : menuBar.height
		UIView.animate(withDuration: 0.5) {
			self.view.layoutIfNeeded()
		}
	}

	@objc func NavigateToUrlFromNotification(_ notification: Notification!)
	{
		guard let urlToNav = notification.userInfo?[AppDelegate.UrlToNavFromNotificationKey] as? String else { return }
		if let url = URL(string: urlToNav) {
			webView.loadRequest(URLRequest(url: url))
		}
	}

	//MARK: -- UIWebViewDelegate
	
	func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool
	{
		if let url = request.url, let host = url.host {
			return host == APP_MAIN_HOST ||
				   	!AppSettings.shared.isValid() ||
					!AppSettings.shared.deniedHosts.contains(host)
		}
		return true
	}
	
	func webViewDidFinishLoad(_ webView: UIWebView)
	{
		if notReady {
			readyDelayTimer?.invalidate()
			readyDelayTimer = Timer.scheduledTimer(timeInterval: 1.2, target: self, selector: #selector(readyToStart), userInfo: nil, repeats: false)
		}
	}
	
	@objc func readyToStart(_ tmr: Timer)
	{
		notReady = false
		revealingSplashView.heartAttack = true
	}
	
	//MARK: -- UITabBarDelegate
	
	func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
	{
		let urlToNav = AppSettings.shared.menuItems[item.tag].urlToNav
		
		
		let alert = UIAlertController(
						title: "Menu!",
						message: "tap on: \(item.title ?? "?")\nand should nav to: \(String(describing: urlToNav))",
						preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
}
