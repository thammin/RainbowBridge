//
//  RainbowBridge.swift
//  RainbowBridge
//
//  Created by 林 柏楊 on 2015/09/11.
//  Copyright © 2015年 林 柏楊. All rights reserved.
//

import WebKit

public class RainbowBridge {
    
    /**
        Create and return WKWebView
    
        :param: frame Size to be use to init WKWebView
        :returns: WKWebView instance
    */
    public class func initWithFrame(frame: CGRect) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let controller = RainbowBridgeController()
        configuration.userContentController.addScriptMessageHandler(controller, name: "rainbowBridge")
        
        let webView = WKWebView.init(frame: frame, configuration: configuration)
        // TODO: take options from user
        webView.allowsBackForwardNavigationGestures = false
        
        return webView
    }
    
}
