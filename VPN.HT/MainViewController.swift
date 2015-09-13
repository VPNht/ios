//
//  MainViewController.swift
//  VPN.HT
//
//  Created by Douwe Bos on 17-05-15.
//  Copyright (c) 2015 Douwe Bos. All rights reserved.
//

import Foundation
import UIKit

class MainViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
	let defaults = NSUserDefaults.standardUserDefaults()
	var username = ""
	var base64LoginString = ""
	
	var apiDictionary : NSDictionary!
	var vpnIPs = [String: String]()
	var vpnKeys : [String]!
	var vpnList = [String: vpnServer]()
	
	let navView = UIView()
	var logo = UIImageView()
	
	var moreButton = UIButton()
	var onDemandLabel = UILabel()
	var onDemandSwitch = UISwitch()
	var onDemandInfoLabel = UILabel()
	var logoutButton = UIButton()
	var vpnNavButton = UIButton()
    var dnsNavButton = UIButton()
    var greenBarView = UIView()
    
    var dragLeft = true
	var moreMenuToggled = false
	var moreMenuAnimating = false

	let moreMenuBackground = UIControl()
	let moreMenuView = UIView()
	
    var vpnPages = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
    var currentIndex = 0
	
    override func viewDidLoad() {
        self.view.backgroundColor = StaticVar.lightBackgroundColor
		
		self.parseServerlist(apiDictionary)
		
        navView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 100)
        navView.backgroundColor = StaticVar.darkBackgroundColor
		
		logo.image = UIImage(named: "navLogo")
		logo.frame = CGRect(x: (self.view.frame.width / 2) - (30/2/657*453), y: 35, width: 30/657*453, height: 30)
		
		moreButton.frame = CGRect(x: self.view.frame.width - 50, y: self.logo.frame.minY - 5, width: 30, height: 30)
		moreButton.setImage(UIImage(named: "more"), forState: UIControlState.Normal)
		moreButton.addTarget(self, action: "toggleMoreMenu:", forControlEvents: UIControlEvents.TouchUpInside)
		moreButton.tintColor = UIColor.clearColor()
		
		moreMenuBackground.frame = self.view.frame
		moreMenuBackground.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 0.3)
		moreMenuBackground.addTarget(self, action: "toggleMoreMenu:", forControlEvents: UIControlEvents.TouchUpInside)
		
		moreMenuView.backgroundColor = StaticVar.darkBackgroundColor
		moreMenuView.frame = CGRect(x: self.view.frame.maxX - 210, y: self.moreButton.frame.maxY, width: 200, height: 152.5)
		
		let mask = CAShapeLayer()
		mask.frame = moreMenuView.layer.bounds
		let width = moreMenuView.layer.frame.size.width
		let height = moreMenuView.layer.frame.size.height
		let path = CGPathCreateMutable()
		CGPathMoveToPoint(path, nil, 20, 20)
		CGPathAddLineToPoint(path, nil, width - 40, 20)
		CGPathAddLineToPoint(path, nil, width - 30, 0)
		CGPathAddLineToPoint(path, nil, width - 20, 20)
		CGPathAddArcToPoint(path, nil, width, 20, width, 30, 10)
		CGPathAddLineToPoint(path, nil, width, height)
		CGPathAddLineToPoint(path, nil, 0, height)
		CGPathAddArcToPoint(path, nil, 0, 20, 20, 20, 10)
		mask.path = path
		moreMenuView.layer.mask = mask
		moreMenuView.layer.cornerRadius = 10;
		moreMenuView.layer.masksToBounds = true;
		
		moreMenuView.frame = CGRect(x: self.view.frame.maxX - 210, y: self.moreButton.frame.maxY, width: 200, height: 0)
		
		onDemandLabel.frame = CGRect(x: 0, y: 27.5, width: 100, height: 35)
		onDemandLabel.text = "On-demand"
		onDemandLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		onDemandLabel.textColor = UIColor.whiteColor()
		onDemandLabel.textAlignment = .Center
		
		onDemandSwitch.frame = CGRect(x: 130, y: 30, width: 100, height: 30)
		onDemandSwitch.tintColor = StaticVar.redBackgroundColor
		onDemandSwitch.onTintColor = StaticVar.greenBackgroundColor
		onDemandSwitch.addTarget(self, action: "toggleOnDemand:", forControlEvents: UIControlEvents.ValueChanged)
		
		if let storedOnDemand = defaults.boolForKey("on-demand") as Bool! {
			if(storedOnDemand) {
				self.onDemandSwitch.setOn(true, animated: true)
			}
		}
		
		onDemandInfoLabel.frame = CGRect(x: 10, y: 62.5, width: 180, height: 48)
		onDemandInfoLabel.text = "On-demand will stop your internet traffic if the connection fails, and it will automatically reconnect."
		onDemandInfoLabel.font = UIFont(name: "Roboto-Light", size: 12)!
		onDemandInfoLabel.textColor = UIColor.whiteColor()
		onDemandInfoLabel.textAlignment = .Left
		onDemandInfoLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
		onDemandInfoLabel.numberOfLines = 3
		
		let infoLabelLayer = onDemandInfoLabel.layer
		let infoLabelBottomBorder = CALayer()
		infoLabelBottomBorder.borderColor = UIColor.darkGrayColor().CGColor
		infoLabelBottomBorder.borderWidth = 1
		infoLabelBottomBorder.frame = CGRectMake(0, onDemandInfoLabel.frame.size.height, onDemandInfoLabel.frame.size.width, 1)
		infoLabelLayer.addSublayer(infoLabelBottomBorder)
		
		logoutButton.frame = CGRect(x: 0, y: 112.5, width: 200, height: 40)
		logoutButton.setTitle("Logout", forState: UIControlState.Normal)
		logoutButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 16)!
		logoutButton.tintColor = UIColor.lightGrayColor()
		logoutButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		logoutButton.addTarget(self, action: "logout:", forControlEvents: UIControlEvents.TouchUpInside)
		
        greenBarView.frame = CGRect(x: 0, y: 96, width: navView.frame.width / 2, height: 4)
        greenBarView.backgroundColor = StaticVar.greenBackgroundColor
        
        vpnNavButton.frame = CGRect(x: 0, y: 60, width: navView.frame.width / 2, height: 40)
        vpnNavButton.setTitle("VPN", forState: UIControlState.Normal)
        vpnNavButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 16)!
        vpnNavButton.tintColor = UIColor.lightGrayColor()
        vpnNavButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		vpnNavButton.addTarget(self, action: "navButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		vpnNavButton.tag = 0
        
        dnsNavButton.frame = CGRect(x: navView.frame.width/2, y: 60, width: navView.frame.width / 2, height: 40)
        dnsNavButton.setTitle("SMART DNS", forState: UIControlState.Normal)
        dnsNavButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 16)!
        dnsNavButton.tintColor = UIColor.lightGrayColor()
        dnsNavButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		dnsNavButton.addTarget(self, action: "navButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		dnsNavButton.tag = 1
		
		moreMenuView.addSubview(onDemandLabel)
		moreMenuView.addSubview(onDemandSwitch)
		moreMenuView.addSubview(onDemandInfoLabel)
		moreMenuView.addSubview(logoutButton)
		
		navView.addSubview(logo)
		navView.addSubview(moreButton)
        navView.addSubview(vpnNavButton)
        navView.addSubview(dnsNavButton)
        navView.addSubview(greenBarView)
        
        let vpnPageViewController = self.viewControllerAtIndex(0)
        self.vpnPages.setViewControllers([vpnPageViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        self.vpnPages.view.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: view.frame.height - 100)
        self.vpnPages.dataSource = self
        self.vpnPages.delegate = self
        self.addChildViewController(self.vpnPages)
        self.view.addSubview(self.vpnPages.view)
        self.vpnPages.didMoveToParentViewController(self)
        
        for view in self.vpnPages.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = self
            }
        }
        
        self.view.addSubview(navView)
    }
	
	//MARK: Pageviewcontroller functions
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = 0
        if #available(iOS 8.0, *) {
            if let controller = viewController as? VpnViewController {
                index = controller.pageIndex
            }
            else if let controller = viewController as? DnsViewController {
                index = controller.pageIndex
            }
        } else {
            // Fallback on earlier versions
        }
        if(index <= 0){
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index)
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = 0
        if #available(iOS 8.0, *) {
            if let controller = viewController as? VpnViewController {
                index = controller.pageIndex
            }
            else if let controller = viewController as? DnsViewController {
                index = controller.pageIndex
            }
        } else {
            // Fallback on earlier versions
        }
        index++
        if(index >= 2){
            return nil
        }
        return self.viewControllerAtIndex(index)
    }
    
    func viewControllerAtIndex(index : Int) -> UIViewController? {
		if(index >= 2) {
			return nil
		}
		
        if(index == 0){
                let controller = VpnViewController()
				controller.username = self.username
				controller.vpnList = self.vpnList
				controller.vpnKeys = self.vpnKeys
				return controller
        }
        else {
            let controller = DnsViewController()
			controller.base64LoginString = self.base64LoginString
            return controller
        }
    }
	
	//MARK: Top menu functions
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let x = (scrollView.contentOffset.x - self.view.frame.width) / 2
        
        if(greenBarView.frame.minX == 0) {
            dragLeft = true
        }
        else if(greenBarView.frame.minX == self.view.frame.width / 2) {
            dragLeft = false
        }
        if(x != 0.0){
            if(dragLeft) {
                greenBarView.frame = CGRectMake(x, 96, self.view.frame.width / 2, 4)
            }
            else {
                greenBarView.frame = CGRectMake((self.view.frame.width / 2) + x, 96, self.view.frame.width / 2, 4)
            }
        }
    }
    
    func setGreenBar(index: Int) {
        greenBarView.frame = CGRectMake(((self.view.frame.width / 2) * CGFloat(index)), 96, self.view.frame.width / 2, 4)
		currentIndex = index
    }
	
	func navButtonPressed(sender: UIButton) {
		if(sender.tag == 0 && currentIndex != 0) {
			self.vpnPages.setViewControllers([self.viewControllerAtIndex(0)!], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
		}
		else if(sender.tag == 1 && currentIndex != 1) {
			self.vpnPages.setViewControllers([self.viewControllerAtIndex(1)!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
		}
	}
	
	func toggleMoreMenu(sender: AnyObject) {
		if(!self.moreMenuAnimating) {
			self.moreMenuAnimating = true
			if(!self.moreMenuToggled) {
				self.moreMenuToggled = true
				self.view.addSubview(self.moreMenuBackground)
				self.view.addSubview(self.moreMenuView)
				let duration1 = 0.5 as NSTimeInterval
				let duration2 = 0.0 as NSTimeInterval
				let duration3 = 0.5 as NSTimeInterval
				
				UIView.animateWithDuration(duration1, delay: duration2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
					self.moreMenuBackground.alpha = 1
					self.moreMenuView.alpha = 1
				}, completion: { finished in })
				
				UIView.animateWithDuration(duration3, delay: duration2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
					self.moreMenuView.frame = CGRect(x: self.moreMenuView.frame.minX, y: self.moreMenuView.frame.minY, width: self.moreMenuView.frame.width, height: 152.5)
				}, completion: { finished in
					self.moreMenuAnimating = false
				})
			}
			else {
				self.moreMenuToggled = false
				let duration1 = 0.5 as NSTimeInterval
				let duration2 = 0.0 as NSTimeInterval
				let duration3 = 0.5 as NSTimeInterval
				
				UIView.animateWithDuration(duration1, delay: duration2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
					self.moreMenuBackground.alpha = 0
					self.moreMenuView.alpha = 0
				}, completion: { finished in })
				
				UIView.animateWithDuration(duration3, delay: duration2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
					self.moreMenuView.frame = CGRect(x: self.moreMenuView.frame.minX, y: self.moreMenuView.frame.minY, width: self.moreMenuView.frame.width, height: 0)
				}, completion: { finished in
					self.moreMenuBackground.removeFromSuperview()
					self.moreMenuView.removeFromSuperview()
					self.moreMenuAnimating = false
				})
			}
		}
	}
	
	func toggleOnDemand(sender: UISwitch) {
		if(sender.on) {
			defaults.setObject(true, forKey: "on-demand")
		}
		else {
			defaults.setObject(false, forKey: "on-demand")
		}
	}
	
	//MARK: Server list
	func parseServerlist(serverlist: NSDictionary) {
		print("Parsing serverlist")
		let servers = serverlist["servers"] as! [[String:AnyObject]]!
		for server in servers  {
			if let country = server["c"] as? String! {
				if let ip = server["h"] as? String! {
					print(server)
					if(country == "Nearest") {
						vpnList["Nearest Server"] = vpnServer(country: "Nearest Server", city: "", ip: ip, long: nil, lat: nil)
					}
					else {
						vpnList[country] = vpnServer(country: country, city: server["l"] as! String!, ip: ip, long: (server["ll"] as! [Float]!)[0], lat: (server["ll"] as! [Float]!)[1])
					}
				}
			}
		}
		vpnKeys = vpnList.keys.sort { (key1, key2) -> Bool in
			if(key2 == "Nearest Server") {
				return false
			}
			else if(key1 == "Nearest Server") {
				return true
			}
			else {
				return key1 < key2
			}
		}
	}
	
	//MARK: Account functions
	func logout(sender: AnyObject) {
		KeychainAccess.deleteData("vpnpassword")
        KeychainAccess.deleteData("sharedsecret")
        GSKeychain.systemKeychain().removeAllSecrets()
        
		self.username = ""
        self.base64LoginString = ""
        
		self.dismissViewControllerAnimated(true) { () -> Void in}
	}
}
