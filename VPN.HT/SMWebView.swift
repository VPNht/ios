//
//  SMWebView
//
//  Created by Shai Mishali on 8/19/15.
//  Copyright (c) 2015 Shai Mishali. All rights reserved.
//

import Foundation
import UIKit

public class SMWebView : UIWebView, UIWebViewDelegate{
    //MARK: Typealiasing for Closure Types
    public typealias SMWebViewClosure                                       = (webView:SMWebView) -> ()
    public typealias SMWebViewFailClosure                                   = (webView:SMWebView, error: NSError) -> ()
    public typealias SMWebViewShouldLoadClosure                             = (webView:SMWebView, request: NSURLRequest, navigationType: UIWebViewNavigationType) -> (Bool)
    
    //MARK: Internal storage for Closures
    internal var __didStartLoadingHandler:SMWebViewClosure?                 = nil
    internal var __didFinishLoadingHandler:SMWebViewClosure?                = nil
    internal var __didCompleteLoadingHandler:SMWebViewClosure?              = nil
    internal var __didFailLoadingHandler:SMWebViewFailClosure?              = nil
    internal var __shouldStartLoadingHandler:SMWebViewShouldLoadClosure?    = nil
    
    //MARK: Initializers
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate  = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate  = self
    }
    
    // URL/String loaders with Chaining-support
    public class func loadURL(URL: NSURL) -> SMWebView{
        let wv = SMWebView()
        wv.loadRequest(NSURLRequest(URL: URL))
        return wv
    }
    
    public class func loadHTML(string: String!, baseURL: NSURL!) -> SMWebView{
        let wv = SMWebView()
        wv.loadHTMLString(string, baseURL: baseURL)
        return wv
    }
    
    public func loadURL(URL: NSURL) -> SMWebView{
        self.loadRequest(NSURLRequest(URL: URL))
        return self
    }
    
    public func loadHTML(string: String!, baseURL: NSURL!) -> SMWebView{
        self.loadHTMLString(string, baseURL: baseURL)
        return self
    }
    
    //MARK: Closure methods
    public func didStartLoading(handler: SMWebViewClosure) -> SMWebView{
        self.__didStartLoadingHandler       = handler
        
        return self
    }
    
    public func didFinishLoading(handler: SMWebViewClosure) -> SMWebView{
        self.__didFinishLoadingHandler      = handler
        return self
    }
    
    public func didFailLoading(handler: SMWebViewFailClosure) -> SMWebView{
        self.__didFailLoadingHandler        = handler
        return self
    }
    
    public func didCompleteLoading(handler: SMWebViewClosure) -> SMWebView{
        self.__didCompleteLoadingHandler    = handler
        return self
    }
    
    public func shouldStartLoading(handler: SMWebViewShouldLoadClosure) -> SMWebView{
        self.__shouldStartLoadingHandler    = handler
        return self
    }
    
    //MARK: UIWebView Delegate & Closure Handling
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        self.__didFailLoadingHandler?(webView: self, error: error!)
    }
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if self.__shouldStartLoadingHandler != nil {
            return self.__shouldStartLoadingHandler!(webView: self, request: request, navigationType: navigationType)
        }
        
        return true
    }
    
    public func webViewDidStartLoad(webView: UIWebView) {
        self.__didStartLoadingHandler?(webView: self)
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        self.__didFinishLoadingHandler?(webView: self)
        
        if !webView.loading {
            self.__didCompleteLoadingHandler?(webView: self)
        }
    }
}