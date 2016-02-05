//
//  ViewController.swift
//  VPN.HT
//
//  Created by Douwe Bos on 17-05-15.
//  Copyright (c) 2015 Douwe Bos. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	var loginView = UIControl()
    var logo = UIImageView()
    var username = UITextField()
    var password = UITextField()
    var login = UIButton()

    var backgroundBlurView = UIView()
    var loadingView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

		self.view.backgroundColor = StaticVar.darkBackgroundColor
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
		
        logo.image = UIImage(named: "logo")
        logo.frame = CGRect(x: 25, y: 0, width: self.view.frame.width - 50, height: (self.view.frame.width - 50) / 841 * 416)
        
        username.frame = CGRect(x: 25, y: self.logo.frame.maxY + 40, width: self.view.frame.width - 50, height: 30)
        username.textColor = UIColor.whiteColor()
        username.font = UIFont(name: "Roboto-Medium", size: 20)!
        username.attributedPlaceholder = NSAttributedString(string:"username", attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        username.autocorrectionType = UITextAutocorrectionType.No
        username.autocapitalizationType = .None
		username.delegate = self
		
        let usernameLayer = username.layer
        let usernameBottomBorder = CALayer()
        usernameBottomBorder.borderColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1).CGColor
        usernameBottomBorder.borderWidth = 1
        usernameBottomBorder.frame = CGRectMake(-1, usernameLayer.frame.size.height-1, usernameLayer.frame.size.width, 1)
        usernameLayer.addSublayer(usernameBottomBorder)
        
        password.frame = CGRect(x: 25, y: self.username.frame.maxY + 20, width: self.view.frame.width - 50, height: 30)
        password.textColor = UIColor.whiteColor()
        password.font = UIFont(name: "Roboto-Medium", size: 20)!
        password.attributedPlaceholder = NSAttributedString(string:"password", attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        password.secureTextEntry = true
		password.delegate = self
		password.keyboardAppearance = UIKeyboardAppearance.Light
		
        let passwordLayer = password.layer
        let passwordBottomBorder = CALayer()
        passwordBottomBorder.borderColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1).CGColor
        passwordBottomBorder.borderWidth = 1
        passwordBottomBorder.frame = CGRectMake(-1, usernameLayer.frame.size.height-1, usernameLayer.frame.size.width, 1)
        passwordLayer.addSublayer(passwordBottomBorder)
        
        login.frame = CGRectMake(25, self.password.frame.maxY + 40, self.view.frame.width - 50, 50)
        login.setTitle("LOGIN", forState: UIControlState.Normal)
        login.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 20)!
        login.addTarget(self, action: "login:", forControlEvents: UIControlEvents.TouchUpInside)
        login.tintColor = StaticVar.greenBackgroundColor
        login.backgroundColor = StaticVar.greenBackgroundColor

        backgroundBlurView.frame = login.frame
        backgroundBlurView.alpha = 0
		backgroundBlurView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 0.5)
		
        loadingView.frame = login.frame
        loadingView.backgroundColor = UIColor.clearColor()
        loadingView.color = StaticVar.darkBackgroundColor
        loadingView.alpha = 0
        loadingView.startAnimating()
		
		let offset = (self.view.frame.height/2)-((self.login.frame.maxY + 20)/2)
		loginView.frame = CGRect(x: 0, y: offset, width: self.view.frame.width, height: self.login.frame.maxY + 20)
        
        self.loginView.addSubview(logo)
        self.loginView.addSubview(username)
        self.loginView.addSubview(password)
        self.loginView.addSubview(login)
        self.loginView.addSubview(backgroundBlurView)
        self.loginView.addSubview(loadingView)
        
        if let username = GSKeychain.systemKeychain().secretForKey("vpnusername") {
            if(username != "") {
                if let password = GSKeychain.systemKeychain().secretForKey("vpnpassword") {
                    if(password != "") {
                        self.username.text = username
                        self.password.text = password
                        toggleLoading(true)
                        self.checkLogin()
                    }
                }
            }
        }
        
		self.view.addSubview(self.loginView)
    }
	
	//MARK: Login functions
    func login(sender: UIButton) {
        if(username.text != "" && password.text != "") {
            toggleLoading(true)
            checkLogin()
        }
        else {
            loginFailed()
        }
    }
    
    func checkLogin() {
        let session = NSURLSession.sharedSession()
        let username = self.username.text!
        let password = self.password.text!
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        
        // create the request
        let url = NSURL(string: "https://api.vpn.ht/servers")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        var returnObject = [:]
        
        let task = session.dataTaskWithRequest(request) {
            data, response, error in
            self.toggleLoading(false)
            if error != nil {
                print("Error: ",error)
                self.loginFailed()
                return
            }
			do {
                print(data)
				let responseObject = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
			
				if responseObject == nil {
					print("Login failed")
					self.loginFailed()
					return
				}
				print("Get servers list: ")
				print(responseObject)
				
				returnObject = responseObject as NSDictionary!
				print(returnObject)
				dispatch_async(dispatch_get_main_queue()) {
					KeychainAccess.storeData("vpnpassword", data: (self.password.text!).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
					KeychainAccess.storeData("sharedsecret", data: ("vpnvpnvpn").dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
					
                    GSKeychain.systemKeychain().setSecret(self.username.text!, forKey: "vpnusername")
                    GSKeychain.systemKeychain().setSecret(self.password.text!, forKey: "vpnpassword")
                    
					self.loginSuccesfull(returnObject, username: username, base64LoginString: base64LoginString)
				}
			}
			catch {
				self.loginFailed()
			}
        }
        task.resume()
    }
    
	func loginSuccesfull(servers: NSDictionary, username: String, base64LoginString: String) {
		let mainVC = MainViewController()
		mainVC.username = username
		mainVC.base64LoginString = base64LoginString
		mainVC.apiDictionary = servers
		self.presentViewController(mainVC, animated: true, completion: nil)
		self.password.text = ""
	}
    
    func loginFailed() {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.1, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.backgroundColor = StaticVar.redBackgroundColor
                }, completion: { finished in })
            UIView.animateWithDuration(0.1, delay: 0.5, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.backgroundColor = StaticVar.greenBackgroundColor
                }, completion: { finished in })
            
            UIView.animateWithDuration(0.05, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.frame = CGRectMake(35, self.password.frame.maxY + 40, self.view.frame.width - 50, 50)
                }, completion: { finished in })
            UIView.animateWithDuration(0.1, delay: 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.frame = CGRectMake(15, self.password.frame.maxY + 40, self.view.frame.width - 50, 50)
                }, completion: { finished in })
            UIView.animateWithDuration(0.1, delay: 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.frame = CGRectMake(35, self.password.frame.maxY + 40, self.view.frame.width - 50, 50)
                }, completion: { finished in })
            UIView.animateWithDuration(0.05, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                self.login.frame = CGRectMake(25, self.password.frame.maxY + 40, self.view.frame.width - 50, 50)
                }, completion: { finished in })
            
            if(self.username.text == "") {
                UIView.animateWithDuration(0.05, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.username.frame = CGRect(x: 35, y: self.logo.frame.maxY + 40, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.1, delay: 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.username.frame = CGRect(x: 15, y: self.logo.frame.maxY + 40, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.1, delay: 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.username.frame = CGRect(x: 35, y: self.logo.frame.maxY + 40, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.05, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.username.frame = CGRect(x: 25, y: self.logo.frame.maxY + 40, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
            }
            if(self.password.text == "") {
                UIView.animateWithDuration(0.05, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.password.frame = CGRect(x: 35, y: self.username.frame.maxY + 20, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.1, delay: 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.password.frame = CGRect(x: 15, y: self.username.frame.maxY + 20, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.1, delay: 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.password.frame = CGRect(x: 35, y: self.username.frame.maxY + 20, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
                UIView.animateWithDuration(0.05, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.password.frame = CGRect(x: 25, y: self.username.frame.maxY + 20, width: self.view.frame.width - 50, height: 30)
                    }, completion: { finished in })
            }
        }
    }
	
	//MARK: Toggles
	func toggleLoading(loading: Bool) {
		if(!loading) {
			dispatch_async(dispatch_get_main_queue()) {
				self.loadingView.alpha = 0
				self.backgroundBlurView.alpha = 0
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue()) {
				UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
					self.loadingView.alpha = 1
					self.backgroundBlurView.alpha = 1
					}, completion: { finished in })
			}
		}
	}
	
	//MARK: Keyboard functions
	func keyboardWillShow(notification: NSNotification) {
		print("Show Keyboard")
		let info = notification.userInfo!
		let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
		
		UIView.animateWithDuration(0.1, animations: { () -> Void in
			self.loginView.frame = CGRect(x: 0, y: keyboardFrame.minY - (self.login.frame.maxY + 20) - 5, width: self.view.frame.width, height: self.login.frame.maxY + 20)
		})
	}
	
	func keyboardWillHide(notification: NSNotification) {
		print("Hide Keyboard")
		
		UIView.animateWithDuration(0.1, animations: { () -> Void in
			let offset = (self.view.frame.height/2)-((self.login.frame.maxY + 20)/2)
			self.loginView.frame = CGRect(x: 0, y: offset, width: self.view.frame.width, height: (self.login.frame.maxY + 20))
		})
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if(textField == self.username) {
			self.password.becomeFirstResponder()
			return false
			
		}
		else if (textField == self.password) {
			self.login(self.login)
			return true
		}
		return false
	}
}
