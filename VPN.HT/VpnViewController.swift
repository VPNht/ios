//
//  VpnViewController.swift
//  VPN.HT
//
//  Created by Douwe Bos on 06-07-15.
//  Copyright © 2015 Douwe Bos. All rights reserved.
//

import Foundation
import MapKit
import NetworkExtension

class VpnViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, MKMapViewDelegate {
	let defaults = NSUserDefaults.standardUserDefaults()
	var checkConnectionTimer:NSTimer!
	var checkConnectionTimerCount = 0
	
	var username : String!
	
	//MARK: VPN Server variables
	var vpnPicker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
	var vpnList : [String:vpnServer]!
	var vpnKeys : [String]!
	var vpnPins : [String:IpAnnotation]!
	var selectedVpn : vpnServer!
	
	var pageIndex = 0
	
	let contentScroll = UIScrollView()
	
	//MARK: Connected UI Elements
	var connectButton = UIButton()
	var connected = false
	var onDemand = false
	
	//MARK: Mapview variables
	let regionRadius: CLLocationDistance = 10000000
	var mapView : MKMapView!
	var yourLocationPin : IpAnnotation!
	var yourLocation = CLLocation()
	
	//MARK: Current IP Location Labels
	var currentIPTitleLabel = UILabel()
	var currentCityTitleLabel = UILabel()
	var currentIPLabel = UILabel()
	var currentCityLabel = UILabel()
	
	//MARK: Server settings UI Elements
	var serverPickerButton = UIButton()
	var serverPickerButtonArrow = UIImageView(image: UIImage(named: "arrow"))
	
	//MARK: Loading views
	var backgroundBlurView = UIView()
	var loadingView = UIActivityIndicatorView()
	
	override func viewDidAppear(animated: Bool) {
		self.getCurrentIpLocation()
		if let mainView = parentViewController?.parentViewController as? MainViewController {
			mainView.setGreenBar(pageIndex)
		}
	}
	
	override func viewDidLoad() {
		self.view.backgroundColor = StaticVar.lightBackgroundColor
		self.selectedVpn = self.vpnList["Nearest Server"] as vpnServer!
		
		contentScroll.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 100)
		
		let locationView = UIControl()
		locationView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: (self.view.frame.width / 1.5) + 85)
		locationView.backgroundColor = UIColor.whiteColor()
		locationView.addTarget(self, action: "displayCurrentLocation:", forControlEvents: UIControlEvents.TouchDownRepeat)
		
		let mapFrame = CGRect(x: 0, y: 0, width: locationView.frame.width, height: (locationView.frame.width) / 1.5)
		
		mapView = MKMapView(frame: mapFrame)
		mapView.delegate = self
		
		currentIPTitleLabel.text = "Current IP:"
		currentIPTitleLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		currentIPTitleLabel.frame = CGRect(x: 10, y: mapView.frame.maxY, width: (locationView.frame.width/2) - 10, height: 40)
		currentIPTitleLabel.backgroundColor = UIColor.clearColor()
		currentIPTitleLabel.textColor = UIColor.lightGrayColor()
		
		currentCityTitleLabel.text = "Current location:"
		currentCityTitleLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		currentCityTitleLabel.frame = CGRect(x: 10, y: currentIPTitleLabel.frame.maxY + 5, width: (locationView.frame.width/2) - 10, height: 40)
		currentCityTitleLabel.backgroundColor = UIColor.clearColor()
		currentCityTitleLabel.textColor = UIColor.lightGrayColor()
		
		currentIPLabel.text = ""
		currentIPLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		currentIPLabel.frame = CGRect(x: self.view.frame.width / 2, y: mapView.frame.maxY, width: (locationView.frame.width/2) - 10, height: 40)
		currentIPLabel.backgroundColor = UIColor.clearColor()
		currentIPLabel.textColor = UIColor.lightGrayColor()
		currentIPLabel.textAlignment = .Right
		
		currentCityLabel.text = "No city available"
		currentCityLabel.font = UIFont(name: "Roboto-Medium", size: 16)!
		currentCityLabel.frame = CGRect(x: self.view.frame.width / 2, y: currentIPTitleLabel.frame.maxY + 5, width: (locationView.frame.width/2) - 10, height: 40)
		currentCityLabel.backgroundColor = UIColor.clearColor()
		currentCityLabel.textColor = UIColor.lightGrayColor()
		currentCityLabel.textAlignment = .Right
		
		locationView.addSubview(mapView)
		locationView.addSubview(currentIPTitleLabel)
		locationView.addSubview(currentCityTitleLabel)
		locationView.addSubview(currentIPLabel)
		locationView.addSubview(currentCityLabel)
		
		serverPickerButton.frame = CGRect(x: 0, y: locationView.frame.maxY + 20, width: self.view.frame.width, height: 50)
		serverPickerButton.setTitle("Nearest server", forState: UIControlState.Normal)
		serverPickerButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 20)!
		serverPickerButton.tintColor = UIColor.lightGrayColor()
		serverPickerButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
		serverPickerButton.addTarget(self, action: "toggleServerPicker:", forControlEvents: UIControlEvents.TouchUpInside)
		serverPickerButton.backgroundColor = UIColor.whiteColor()
		
		serverPickerButtonArrow.frame = CGRect(x: self.view.frame.width - 35, y: serverPickerButton.frame.minY + 15 + (20 * 0.25), width: 20, height: 20*0.5)
		serverPickerButtonArrow.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
		
		vpnPicker.delegate = self
		vpnPicker.dataSource = self
		vpnPicker.frame = CGRect(x: self.serverPickerButton.frame.minX, y: self.serverPickerButton.frame.maxY, width: self.serverPickerButton.frame.width, height: 162)
		vpnPicker.selectRow(0, inComponent: 0, animated: false)
		vpnPicker.backgroundColor = UIColor.whiteColor()
		vpnPicker.hidden = true
		
		let serverPickerLayer = vpnPicker.layer
		let serverPickerTopBorder = CALayer()
		serverPickerTopBorder.borderColor = UIColor.lightGrayColor().CGColor
		serverPickerTopBorder.borderWidth = 1
		serverPickerTopBorder.frame = CGRectMake(10, 0, serverPickerLayer.frame.size.width - 20, 1)
		serverPickerLayer.addSublayer(serverPickerTopBorder)
		
		connectButton.frame = CGRectMake(CGFloat(0), self.serverPickerButton.frame.maxY + 20, self.view.frame.width, CGFloat(50))
		connectButton.backgroundColor = StaticVar.greenBackgroundColor
		connectButton.setTitle("CONNECT", forState: UIControlState.Normal)
		connectButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 20)!
		connectButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		connectButton.addTarget(self, action: "toggleConnection:", forControlEvents: UIControlEvents.TouchUpInside)
		
		contentScroll.addSubview(locationView)
		contentScroll.addSubview(serverPickerButton)
		contentScroll.addSubview(serverPickerButtonArrow)
		contentScroll.addSubview(vpnPicker)
		contentScroll.addSubview(connectButton)
		
		contentScroll.contentSize = CGSize(width: self.view.frame.width, height: connectButton.frame.maxY + 20)
		
		backgroundBlurView.frame = locationView.frame
		backgroundBlurView.alpha = 0
		backgroundBlurView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 0.5)
		
		loadingView.frame = locationView.frame
		loadingView.backgroundColor = UIColor.clearColor()
		loadingView.color = StaticVar.darkBackgroundColor
		loadingView.alpha = 0
		loadingView.startAnimating()
		
		contentScroll.addSubview(backgroundBlurView)
		contentScroll.addSubview(loadingView)
		
		self.view.addSubview(contentScroll)
		self.toggleLoading(true)
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
			self.getCurrentIpLocation()
			self.addServersToMap()
		}
	}
	
	//MARK: Mapview functions
	func getCurrentIpLocation() {
		self.removeCurrentIPLocation()
		
		let session = NSURLSession.sharedSession()
		let url = NSURL(string: "https://myip.ht/status")
		let request = NSMutableURLRequest(URL: url!)
		request.HTTPMethod = "GET"
		
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
					let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
					print("ResponseString: ",responseString)
					return
				}
				returnObject = responseObject as NSDictionary!
				print(returnObject)
				dispatch_async(dispatch_get_main_queue()) {
					if let connected = returnObject["connected"] as? Bool {
						if(connected) {
							if(self.connected == false) {
								self.toggleHideServerPickerButton(true)
							}
							self.connectButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
							self.connectButton.backgroundColor = StaticVar.redBackgroundColor
							
							self.connected = true
						}
						else {
							if(self.connected) {
								self.toggleHideServerPickerButton(false)
							}
							if(!(self.checkConnectionTimerCount > 0 && self.checkConnectionTimerCount < 6)) {
								self.connectButton.setTitle("CONNECT", forState: UIControlState.Normal)
							}
							self.connectButton.backgroundColor = StaticVar.greenBackgroundColor
							
							self.connected = false
						}
					}
					
					if let ip = returnObject["ip"] as? String {
						self.currentIPLabel.text = ip
					}
					
					if let coordinates = returnObject["coordinates"] as? [Float] {
						self.yourLocation = CLLocation(latitude: CLLocationDegrees(coordinates[0]), longitude: CLLocationDegrees(coordinates[1]))
						self.yourLocationPin = IpAnnotation(coordinate: self.yourLocation.coordinate)
						self.yourLocationPin.title = "Your location"
						self.yourLocationPin.subtitle = self.currentIPLabel.text
						
						if(self.connected) {
							self.yourLocationPin.categoryID = 1
						}
						else {
							self.yourLocationPin.categoryID = 0
						}
						
						self.mapView.addAnnotation(self.yourLocationPin)
						self.centerMapOnLocation(self.yourLocation)
						
						let location = CLLocation(latitude: CLLocationDegrees(coordinates[0]), longitude: CLLocationDegrees(coordinates[1]))
						
						if(self.connected) {
							if(self.selectedVpn.country == "Nearest Server") {
								if let advanced = returnObject["advanced"] as! NSDictionary! {
									if let country = advanced["countryName"] as? String {
										self.currentCityLabel.text = "\(country)"
										if let city = advanced["countryName"] as? String {
											self.yourLocationPin.subtitle = "\(country) - \(city)"
										}
										else {
											if let server = self.vpnList[country] as vpnServer! {
												self.yourLocationPin.subtitle = "\(country) - \(server.city)"
											}
											else {
												self.yourLocationPin.subtitle = country
											}
										}
									}
									else {
										self.currentCityLabel.text = "No country available"
									}
								}
								else {
									self.currentCityLabel.text = "No country available"
								}
							}
							else {
								self.currentCityLabel.text = "\(self.selectedVpn.country)"
								self.yourLocationPin.subtitle = "\(self.selectedVpn.country) - \(self.selectedVpn.city)"
							}
							
						}
						else {
							CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
								if error != nil {
									print("Reverse geocoder failed with error" + error!.localizedDescription)
									return
								}
								if let pms = placemarks as [CLPlacemark]! {
									if pms.count > 0 {
										if let pm = pms[0] as CLPlacemark! {
											if let locality = pm.locality as String! {
												self.currentCityLabel.text = locality
											}
											else {
												self.currentCityLabel.text = "No city available"
											}
										}
									}
								}
								else {
									print("Problem with the data received from geocoder")
									self.currentCityLabel.text = "No city available"
								}
							})
						}
					}
					self.toggleLoading(false)
				}
			}
			catch {
				
			}
		}
		task.resume()
	}
	
	func removeCurrentIPLocation() {
		for var annotation in self.mapView.annotations {
			if let ipAnnotation = annotation as? IpAnnotation {
				if(ipAnnotation.categoryID == 0 || ipAnnotation.categoryID == 1) {
					self.mapView.removeAnnotation(ipAnnotation)
				}
			}
		}
	}
	
	func addServersToMap() {
		for key in vpnKeys {
			if(key != "Nearest Server") {
				let server = vpnList[key] as vpnServer!
				let lat = server.lat
				let long = server.long
				let country = server.country
				let city = server.city
				let title = country == city ? country : "\(country)" as String!
				let ip = server.ip
				let serverLocation = CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))
				let serverLocationPin = IpAnnotation(coordinate: serverLocation.coordinate)
				serverLocationPin.subtitle = "Server - \(title) - \(city)"
				serverLocationPin.title = title
				serverLocationPin.ipAddress = ip
				serverLocationPin.categoryID = 2
				serverLocationPin.location = key
				
				self.mapView.addAnnotation(serverLocationPin)
			}
		}
		self.getCurrentIpLocation()
	}
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
		annotationView.canShowCallout = true
		
		if #available(iOS 9.0, *) {
			if((annotation as! IpAnnotation).categoryID == 0) {
				annotationView.pinTintColor = UIColor.redColor()
			}
			else if ((annotation as! IpAnnotation).categoryID == 1) {
				annotationView.pinTintColor = UIColor.greenColor()
			}
			else if ((annotation as! IpAnnotation).categoryID == 2) {
				annotationView.pinTintColor = UIColor.blueColor()
			}
			else if ((annotation as! IpAnnotation).categoryID == 3) {
				annotationView.pinTintColor = UIColor.purpleColor()
			}
		}
		else {
			if((annotation as! IpAnnotation).categoryID == 0) {
				annotationView.pinColor = MKPinAnnotationColor.Red
			}
			else if ((annotation as! IpAnnotation).categoryID == 1) {
				annotationView.pinColor = MKPinAnnotationColor.Green
			}
			else if ((annotation as! IpAnnotation).categoryID == 2) {
				annotationView.pinColor = MKPinAnnotationColor.Purple
			}
			else if ((annotation as! IpAnnotation).categoryID == 3) {
				annotationView.pinColor = MKPinAnnotationColor.Purple
			}
		}
		return annotationView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		let pin = view.annotation as! IpAnnotation
		if(pin.categoryID != 0 && !self.connected && self.checkConnectionTimerCount == 0) {
			self.serverPickerButton.setTitle(pin.title, forState: UIControlState.Normal)
			self.selectedVpn = self.vpnList[pin.location!] as vpnServer!
		}
	}
	
	func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
		self.serverPickerButton.setTitle("Nearest server", forState: UIControlState.Normal)
		self.selectedVpn = self.vpnList["Nearest Server"] as vpnServer!
	}
	
	func centerMapOnLocation(location: CLLocation) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
			regionRadius * 1.0, regionRadius * 1.0)
			mapView.setRegion(coordinateRegion, animated: true)
	}
	
	func displayCurrentLocation(sender: UIControl) {
		centerMapOnLocation(yourLocation)
	}
	
	//MARK: Toggles
	func toggleLoading(loading: Bool) {
		if(!loading) {
			UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.loadingView.alpha = 0
				self.backgroundBlurView.alpha = 0
				}, completion: { finished in })
		}
		else {
			UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.loadingView.alpha = 1
				self.backgroundBlurView.alpha = 1
				}, completion: { finished in })
		}
	}
	
	func toggleHideServerPickerButton(hide: Bool) {
		if(hide) {
			if(self.vpnPicker.frame.height != 0 && !self.vpnPicker.hidden) {
				self.toggleServerPicker(self.serverPickerButton)
			}
			UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.serverPickerButton.frame = CGRect(x: self.serverPickerButton.frame.minX, y: self.serverPickerButton.frame.minY, width: self.serverPickerButton.frame.width, height: 0)
				self.serverPickerButton.alpha = 0
				self.serverPickerButtonArrow.frame = CGRect(x: self.serverPickerButtonArrow.frame.minX, y: self.serverPickerButtonArrow.frame.minY, width: self.serverPickerButtonArrow.frame.width, height: 0)
				self.connectButton.frame = CGRectMake(CGFloat(0), self.serverPickerButton.frame.minY, self.view.frame.width, CGFloat(50))
				}, completion: { finished in
					self.contentScroll.contentSize = CGSize(width: self.view.frame.width, height: self.connectButton.frame.maxY + 20)
				}
			)
		}
		else {
			UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.serverPickerButton.frame = CGRect(x: self.serverPickerButton.frame.minX, y: self.serverPickerButton.frame.minY, width: self.serverPickerButton.frame.width, height: 50)
				self.serverPickerButton.alpha = 1
				self.serverPickerButtonArrow.frame = CGRect(x: self.serverPickerButtonArrow.frame.minX, y: self.serverPickerButtonArrow.frame.minY, width: self.serverPickerButtonArrow.frame.width, height: 20*0.5)
				self.connectButton.frame = CGRectMake(CGFloat(0), self.serverPickerButton.frame.maxY + 20, self.view.frame.width, CGFloat(50))
				self.contentScroll.contentSize = CGSize(width: self.view.frame.width, height: self.connectButton.frame.maxY + 20)
				}, completion: { finished in }
			)
		}
	}
	
	func toggleServerPicker(sender: UIButton) {
		if(self.vpnPicker.hidden) {
			UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.vpnPicker.frame = CGRect(x: self.vpnPicker.frame.minX, y: self.vpnPicker.frame.minY, width: self.vpnPicker.frame.width, height: 162)
				self.connectButton.frame = CGRectMake(CGFloat(0), self.vpnPicker.frame.minY + 182, self.view.frame.width, CGFloat(50))
				self.contentScroll.contentSize = CGSize(width: self.view.frame.width, height: self.connectButton.frame.maxY + 20)
				self.vpnPicker.hidden = false
				}, completion: { finished in })
			
			UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.serverPickerButtonArrow.transform = CGAffineTransformMakeRotation((0.0 * CGFloat(M_PI)) / 180.0)
				}, completion: { finished in })
		}
		else {
			UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.connectButton.frame = CGRectMake(CGFloat(0), self.serverPickerButton.frame.maxY + 20, self.view.frame.width, CGFloat(50))
				self.contentScroll.contentSize = CGSize(width: self.view.frame.width, height: self.connectButton.frame.maxY + 20)
				}, completion: { finished in })
			
			UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
				self.serverPickerButtonArrow.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
				}, completion: { finished in })
			self.vpnPicker.hidden = true
		}
	}
	
	func toggleConnection(sender: UIButton) {
		if #available(iOS 8.0, *) {
			let manager = NEVPNManager.sharedManager()
			
			if let storedOnDemand = defaults.boolForKey("on-demand") as Bool! {
				self.onDemand = storedOnDemand
			}
			else {
				self.onDemand = false
			}
			
			if(!self.connected){
				manager.loadFromPreferencesWithCompletionHandler { (error) -> Void in
					if((error) != nil) {
						print("VPN Preferences error: 1")
						let alertController = UIAlertController(title: "Oops..", message:
							"Something went wrong loading the VPN Preferences. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
						alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
						
						self.presentViewController(alertController, animated: true, completion: nil)
					}
					else {
						print("Connect to VPN: \n\tUsername: \(self.username)\n\tIP: \(self.selectedVpn.ip)")
						let p = NEVPNProtocolIPSec()
						p.username = "\(self.username)"
						p.serverAddress = "\(self.selectedVpn.ip)"
						p.passwordReference = KeychainAccess.getData("vpnpassword")
						p.authenticationMethod = NEVPNIKEAuthenticationMethod.SharedSecret
						p.sharedSecretReference = KeychainAccess.getData("sharedsecret")
						p.localIdentifier = ""
						p.remoteIdentifier = ""
						p.useExtendedAuthentication = true
						p.disconnectOnSleep = false
						manager.`protocol` = p
						manager.onDemandEnabled = true
						manager.localizedDescription = "VPN.HT"
						
						if(self.onDemand) {
							manager.onDemandEnabled = true
						}
						else {
							manager.onDemandEnabled = false
						}
						
						let connectRule = NEOnDemandRuleConnect()
						manager.onDemandRules = [connectRule]
						
						manager.saveToPreferencesWithCompletionHandler({ (error) -> Void in
							if((error) != nil) {
								print("VPN Preferences error: 2")
								let alertController = UIAlertController(title: "Oops..", message:
									"Something went saving the VPN Preferences. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
								alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
								
								self.presentViewController(alertController, animated: true, completion: nil)
								print(error)
							}
							else {
								var startError: NSError?
								do {
									try manager.connection.startVPNTunnel()
								}
								catch let error as NSError {
									startError = error
									print(startError)
								}
								catch {
									print("Fatal Error")
									fatalError()
								}
								if((startError) != nil) {
									print("VPN Preferences error: 3")
									let alertController = UIAlertController(title: "Oops..", message:
										"Something went connecting to the VPN. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
									alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
									
									self.presentViewController(alertController, animated: true, completion: nil)
									print(startError)
								}
								else {
									print("Start VPN")
									self.connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
									self.checkConnectionTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("checkVPNConnection"), userInfo: nil, repeats: true)
									self.checkVPNConnection()
								}
							}
						})
					}
				}
			}
			else {
				manager.loadFromPreferencesWithCompletionHandler({ (error) -> Void in
					if((error) != nil) {
						print("VPN Preferences error: 1")
						let alertController = UIAlertController(title: "Oops..", message:
							"Something went wrong disconnecting from the VPN. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
						alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
						
						self.presentViewController(alertController, animated: true, completion: nil)
					}
					else {
						if(self.onDemand) {
							manager.onDemandEnabled = true
							print("VPN Preferences error: 5")
							let alertController = UIAlertController(title: "Oops..", message:
								"VPN On-demand is still enabled. Please turn this off before disconnecting.", preferredStyle: UIAlertControllerStyle.Alert)
							alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
							
							self.presentViewController(alertController, animated: true, completion: nil)
						}
						else {
							manager.onDemandEnabled = false
							manager.saveToPreferencesWithCompletionHandler({ (error) -> Void in
								if((error) != nil) {
									print("VPN Preferences error: 4")
									let alertController = UIAlertController(title: "Oops..", message:
										"Something went saving saving the VPN On-demand Preferences. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
									alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
									
									self.presentViewController(alertController, animated: true, completion: nil)
									print(error)
								}
								else {
									self.connectButton.setTitle("Disconnecting...", forState: UIControlState.Normal)
									manager.connection.stopVPNTunnel()
									_ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("getCurrentIpLocation"), userInfo: nil, repeats: false)
								}
							})
						}
					}
				})
			}
		}
		else {
			//If Client is running iOS 7
			//Fallback using VPN Confirgurations
			let alert = UIAlertView()
			alert.title = "Oops"
			alert.message = "We do not support iOS 7 yet."
			alert.addButtonWithTitle("Done")
			alert.show()
		}
	}
	
	//Mark: Check VPN Connection
	func checkVPNConnection() {
		print(self.connected)
		if(!self.connected) {
			if(self.checkConnectionTimerCount < 6) {
				self.connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
				self.getCurrentIpLocation()
				self.checkConnectionTimerCount++
			}
			else {
				self.checkConnectionTimerCount = 0
				self.checkConnectionTimer.invalidate()
			}
		}
		else {
			self.checkConnectionTimerCount = 0
			self.checkConnectionTimer.invalidate()
		}
	}
	
	//MARK: VPN Picker Delegate and Datasource
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return vpnKeys.count
	}
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
		let title = vpnKeys[row] as String!
		return (title as String!)
	}
 
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let serverLocation = vpnKeys[row]
		self.selectedVpn = vpnList[serverLocation]!
		
		if(self.mapView.selectedAnnotations.count > 0) {
			for annotation in self.mapView.selectedAnnotations {
				self.mapView.deselectAnnotation(annotation, animated: false)
			}
		}
		
		serverPickerButton.setTitle(serverLocation, forState: UIControlState.Normal)
	}
}