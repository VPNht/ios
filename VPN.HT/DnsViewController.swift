//
//  DnsViewController.swift
//  VPN.HT
//
//  Created by Douwe Bos on 06-07-15.
//  Copyright © 2015 Douwe Bos. All rights reserved.
//

import UIKit
import Foundation

class DnsViewController: UIViewController {
	var pageIndex = 1
	
	var base64LoginString = ""
	
	let dnsView = UIView()
	var dns1IPTitleLabel = UILabel()
	var dns1IPLabel = UILabel()
	var copyDNS1Button = UIButton()
	var dns2IPTitleLabel = UILabel()
	var dns2IPLabel = UILabel()
	var copyDNS2Button = UIButton()
	var messageView = UIView()
	var messageLabel = UILabel()
	var messageVisible = false
	var dnsTutorialButton = UIButton()
	
	override func viewDidAppear(animated: Bool) {
		if let mainView = parentViewController?.parentViewController as? MainViewController {
			mainView.setGreenBar(pageIndex)
		}
		self.displayMessage("Tip: Touch the address to copy it")
	}
	
	override func viewDidLoad() {
		self.view.backgroundColor = StaticVar.lightBackgroundColor
		//https://api.vpn.ht/smartdns
		
		let session = NSURLSession.sharedSession()
		
		// create the request
		let url = NSURL(string: "https://api.vpn.ht/smartdns")
		let request = NSMutableURLRequest(URL: url!)
		request.HTTPMethod = "GET"
		request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
		
		var returnObject = [:]
		
		let task = session.dataTaskWithRequest(request) {
			data, response, error in
			if error != nil {
				print("Error: ",error)
				return
			}
			do {
				let responseObject = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
				
				if responseObject == nil {
					print("Login failed")
					return
				}
				print("Getting DNS Servers list")
				
				returnObject = responseObject as NSDictionary!
				
				dispatch_async(dispatch_get_main_queue()) {
					if let dnsServers = returnObject["dns"] as! [String]! {
						if(dnsServers.count == 2) {
							self.dns1IPLabel.text = dnsServers[0]
							self.dns2IPLabel.text = dnsServers[1]
						}
					}
				}
			}
			catch {
				
			}
		}
		task.resume()
	
		dnsView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: 100)
		dnsView.backgroundColor = UIColor.whiteColor()
	
		dns1IPTitleLabel.text = "DNS Address 1:"
		dns1IPTitleLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		dns1IPTitleLabel.frame = CGRect(x: 10, y: 0, width: (dnsView.frame.width/2) - 10, height: 50)
		dns1IPTitleLabel.backgroundColor = UIColor.clearColor()
		dns1IPTitleLabel.textColor = UIColor.lightGrayColor()
		
		dns1IPLabel.text = ""
		dns1IPLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		dns1IPLabel.frame = CGRect(x: (dnsView.frame.width/2), y: 0, width: (dnsView.frame.width/2) - 10, height: 50)
		dns1IPLabel.backgroundColor = UIColor.clearColor()
		dns1IPLabel.textColor = UIColor.lightGrayColor()
		dns1IPLabel.textAlignment = .Right
		
		copyDNS1Button.frame = CGRect(x: 10, y: 0, width: dnsView.frame.width - 20, height: 50)
		copyDNS1Button.backgroundColor = UIColor.clearColor()
		copyDNS1Button.addTarget(self, action: "copyDNSToClipboard:", forControlEvents: UIControlEvents.TouchUpInside)
		
		let copyDNS1ButtonLayer = copyDNS1Button.layer
		let copyDNS1ButtonBottomBorder = CALayer()
		copyDNS1ButtonBottomBorder.borderColor = UIColor.lightGrayColor().CGColor
		copyDNS1ButtonBottomBorder.borderWidth = 1
		copyDNS1ButtonBottomBorder.frame = CGRectMake(0, copyDNS1ButtonLayer.frame.size.height-1, copyDNS1ButtonLayer.frame.size.width, 1)
		copyDNS1ButtonLayer.addSublayer(copyDNS1ButtonBottomBorder)
		
		dns2IPTitleLabel.text = "DNS Address 2:"
		dns2IPTitleLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		dns2IPTitleLabel.frame = CGRect(x: 10, y: dns1IPLabel.frame.maxY, width: (dnsView.frame.width/2) - 10, height: 50)
		dns2IPTitleLabel.backgroundColor = UIColor.clearColor()
		dns2IPTitleLabel.textColor = UIColor.lightGrayColor()
		
		dns2IPLabel.text = ""
		dns2IPLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		dns2IPLabel.frame = CGRect(x: (dnsView.frame.width/2), y: dns1IPLabel.frame.maxY, width: (dnsView.frame.width/2) - 10, height: 50)
		dns2IPLabel.backgroundColor = UIColor.clearColor()
		dns2IPLabel.textColor = UIColor.lightGrayColor()
		dns2IPLabel.textAlignment = .Right
		
		copyDNS2Button.frame = CGRect(x: 10, y: dns1IPLabel.frame.maxY, width: dnsView.frame.width - 20, height: 50)
		copyDNS2Button.backgroundColor = UIColor.clearColor()
		copyDNS2Button.addTarget(self, action: "copyDNSToClipboard:", forControlEvents: UIControlEvents.TouchUpInside)
		
		messageView.frame = CGRect(x: 0, y: copyDNS2Button.frame.maxY - 50, width: self.view.frame.width, height: 100)
		
		messageLabel.frame = CGRect(x: 0, y: 50, width: self.view.frame.width, height: 50)
		messageLabel.backgroundColor = UIColor.whiteColor()
		messageLabel.text = ""
		messageLabel.textAlignment = .Center
		messageLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		messageLabel.textColor = UIColor.lightGrayColor()
		
		messageView.addSubview(messageLabel)
		messageView.layer.transform = CATransform3DMakeRotation((CGFloat(M_PI) * 90/180), 1.0, 0.0, 0.0)
		
		dnsTutorialButton.frame = CGRect(x: 0, y: self.dnsView.frame.maxY + 20, width: dnsView.frame.width, height: 50)
		dnsTutorialButton.setTitle("How to use SmartDNS", forState: UIControlState.Normal)
		dnsTutorialButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 20)!
		dnsTutorialButton.backgroundColor = StaticVar.greenBackgroundColor
		dnsTutorialButton.tintColor = UIColor.whiteColor()
		dnsTutorialButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		dnsTutorialButton.addTarget(self, action: "showTutorial:", forControlEvents: UIControlEvents.TouchUpInside)
		
		dnsView.addSubview(dns1IPTitleLabel)
		dnsView.addSubview(dns1IPLabel)
		dnsView.addSubview(dns2IPTitleLabel)
		dnsView.addSubview(dns2IPLabel)
		dnsView.addSubview(messageView)
		dnsView.addSubview(copyDNS1Button)
		dnsView.addSubview(copyDNS2Button)
		
		self.view.addSubview(dnsView)
		self.view.addSubview(dnsTutorialButton)
	}
	
	func copyDNSToClipboard(sender: UIButton) {
		if(self.dns1IPLabel.text != "") {
			if(sender == self.copyDNS1Button) {
				UIPasteboard.generalPasteboard().string = self.dns1IPLabel.text
			}
			else {
				UIPasteboard.generalPasteboard().string = self.dns2IPLabel.text
			}
			displayMessage("Copied to Clipboard")
		}
		else {
			displayMessage("DNS Addresses are still loading.")
		}
	}
	
	func displayMessage(message: String) {
		self.messageLabel.text = message
		
		UIView.animateWithDuration(0.5, animations: { () -> Void in
			self.messageView.layer.transform = CATransform3DMakeRotation((CGFloat(M_PI) * 0/180), 1.0, 0.0, 0.0)
			self.dnsTutorialButton.frame = CGRect(x: 0, y: self.dnsView.frame.maxY + 70, width: self.view.frame.width, height: 50)
		}, completion: { finished in
			UIView.animateWithDuration(0.5, delay: 1.5, options: [], animations: {
				self.messageView.layer.transform = CATransform3DMakeRotation((CGFloat(M_PI) * 90/180), 1.0, 0.0, 0.0)
				self.dnsTutorialButton.frame = CGRect(x: 0, y: self.dnsView.frame.maxY + 20, width: self.view.frame.width, height: 50)
			}, completion: { finished in })
		})
	}
	
	func showTutorial(sender: UIButton) {
		let smartDnsTutorialViewController = SmartDnsTutorialViewController()
		smartDnsTutorialViewController.navigationController?.navigationBar.barTintColor = StaticVar.darkBackgroundColor
		let dnsTutorial = UINavigationController(rootViewController: smartDnsTutorialViewController)
		self.presentViewController(dnsTutorial, animated: true, completion: nil)
	}
}

class SmartDnsTutorialViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	let dnsPages = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
	
	override func viewDidLoad() {
		self.automaticallyAdjustsScrollViewInsets = false
		self.navigationController?.navigationBar.barTintColor = StaticVar.darkBackgroundColor
		let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "hideTutorialView:")
		doneButton.tintColor = StaticVar.lightBackgroundColor
		self.navigationItem.setRightBarButtonItem(doneButton, animated: false)
		self.navigationController?.navigationBar.barTintColor = StaticVar.darkBackgroundColor
		self.view.backgroundColor = StaticVar.darkBackgroundColor
		
		let dnsTutorialStepViewController = self.viewControllerAtIndex(0)
		self.dnsPages.setViewControllers([dnsTutorialStepViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
		self.dnsPages.view.frame = self.view.frame
		self.dnsPages.dataSource = self
		self.dnsPages.delegate = self
		self.addChildViewController(self.dnsPages)
		self.view.addSubview(self.dnsPages.view)
		self.dnsPages.didMoveToParentViewController(self)
	}
	
	func hideTutorialView(sender: UIBarButtonItem) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	//MARK: Pageviewcontroller functions
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		var index = 0
		
		if let controller = viewController as? SmartDnsTutorialStepViewController {
			index = controller.index
		}
		else {
			index = 0
		}
		
		if(index <= 0){
			return nil
		}
		
		index--
		return self.viewControllerAtIndex(index)
	}
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		var index = 0
		
		if let controller = viewController as? SmartDnsTutorialStepViewController {
			index = controller.index
		}
		else {
			return nil
		}
		
		index++
		if(index >= 6){
			return nil
		}
		return self.viewControllerAtIndex(index)
	}
	
	func viewControllerAtIndex(index : Int) -> UIViewController? {
		if(index >= 6) {
			return nil
		}
		let controller = SmartDnsTutorialStepViewController()
		controller.index = index
		return controller
	}
}

class SmartDnsTutorialStepViewController: UIViewController, UIScrollViewDelegate {
	var index = 0
	var activeView = false

	var contentScroll = UIScrollView()
	var image = UIImageView()
	var text = UILabel()
	
	override func viewDidLoad() {
		self.view.clipsToBounds = true
		self.view.backgroundColor = StaticVar.darkBackgroundColor
		self.contentScroll.userInteractionEnabled = false
		self.contentScroll.frame = CGRect(x: 0, y: (self.view.frame.height - (self.view.frame.width / 640 * 681)) / 2, width: self.view.frame.width, height: self.view.frame.width / 640 * 681)
		
		self.image.image = UIImage(named: "dnsTutorialiPhone\(index + 1)")
		self.image.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width / 640 * 681)
		
		self.text.frame = CGRect(x: self.view.frame.width * 0.05, y: self.contentScroll.frame.maxY + 5, width: self.view.frame.width - (self.view.frame.width * 0.1), height: self.view.frame.height - self.contentScroll.frame.maxY - 10)
		self.text.textColor = UIColor.whiteColor()
		self.text.lineBreakMode = NSLineBreakMode.ByWordWrapping
		self.text.numberOfLines = 0
		self.text.font = UIFont(name: "Roboto-Medium", size: 16)!
		self.text.backgroundColor = StaticVar.darkBackgroundColor
		
		switch(self.index) {
		case (0):
			self.text.text = "Open your settings app and go to your Wi-Fi setings."
			break;
		case (1):
			self.text.text = "Tap on the info (i) icon next to the network you're connected to."
			break;
		case (2):
			self.image.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 10, height: (self.view.frame.width + 10) / 640 * 977)
			self.text.text = "Scroll down until you see a row titled \"DNS\"."
			break;
		case (3):
			self.text.text = "Delete the IP address that's currently being used."
			break;
		case (4):
			self.text.text = "Replace it with a VPN.HT DNS Address. \nTip: You can easily copy paste your addresses."
			break;
		case (5):
			self.text.text = "Go back to save your settings.\nNow you're all set to use SmartDNS!"
			break;
		default:
			break;
		}
		
		self.contentScroll.contentSize = CGSize(width: self.view.frame.width, height: self.image.frame.height)
		self.contentScroll.addSubview(self.image)
		self.view.addSubview(self.text)
		self.view.addSubview(self.contentScroll)
	}
	
	override func viewWillAppear(animated: Bool) {
		if let dnsPages = self.parentViewController as? UIPageViewController! {
			for view in dnsPages.view.subviews {
				if let scrollView = view as? UIScrollView {
					scrollView.delegate = self
				}
			}
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		self.activeView = true
		if(self.index == 2) {
			UIView.animateWithDuration(3.0, delay: 1.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: {
				self.contentScroll.contentOffset = CGPoint(x: 0, y: self.image.frame.height - (self.view.frame.width / 640 * 681))
			}, completion: { finished in })
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		self.image.frame = CGRect(x: 0, y: 0, width: self.image.frame.width, height: self.image.frame.height)
	}
	
	override func viewDidDisappear(animated: Bool) {
		self.activeView = false
		if(self.index == 2) {
			self.contentScroll.contentOffset = CGPoint(x: 0, y: 0)
		}
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		let percentage = (scrollView.contentOffset.x - scrollView.frame.width) / scrollView.frame.width
		if(percentage > 0.0 && !self.activeView) {
			self.image.frame = CGRect(x: 0 - (self.view.frame.width * (1 - percentage)), y: 0, width: self.image.frame.width, height: self.image.frame.height)
			self.text.frame = CGRect(x: (self.view.frame.width * 0.05) - (self.view.frame.width * (1 - percentage)), y: self.text.frame.minY, width: self.text.frame.width, height: self.text.frame.height)
		}
		
		if(percentage < 0.0 && !self.activeView) {
			self.image.frame = CGRect(x: 0 + (self.view.frame.width * (1 + percentage)), y: 0, width: self.image.frame.width, height: self.image.frame.height)
			self.text.frame = CGRect(x: (self.view.frame.width * 0.05) + (self.view.frame.width * (1 + percentage)), y: self.text.frame.minY, width: self.text.frame.width, height: self.text.frame.height)
		}
		
		if(percentage == 0.0) {
			self.image.frame = CGRect(x: 0, y: 0, width: self.image.frame.width, height: self.image.frame.height)
			self.text.frame = CGRect(x: self.view.frame.width * 0.05, y: self.contentScroll.frame.maxY + 5, width: self.text.frame.width, height: self.text.frame.height)
		}
	}
}
