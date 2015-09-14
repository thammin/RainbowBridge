//
//  RainbowBridgeController.swift
//  RainbowBridge
//
//  Created by 林 柏楊 on 2015/09/11.
//  Copyright © 2015年 林 柏楊. All rights reserved.
//

import WebKit
import AudioToolbox

class RainbowBridgeController: WKUserContentController, WKScriptMessageHandler {
    
    // reference to webView
    var webView: WKWebView! = nil
    
    /**
    Set the target webView as reference
    
    :param: view Target's view
    */
    func setTargetView(view: WKWebView) {
        self.webView = view
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if message.body is NSNull {
            print("Null is not allowed.")
            return
        }
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(message.body.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.MutableContainers)
            callNativeApi(withObject: json)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    /**
    Native api wrapper
    TODO: add parameters as arguments
    
    :param: withObject JSON object
    */
    func callNativeApi(withObject object: AnyObject) {
        if object["wrappedApiName"] as? String != nil {
            let wrappedApiName = object["wrappedApiName"]! as! String
        
            switch wrappedApiName {
            case "playVibration":
                self._playVibration()
            default:
                print("Invalid wrapped api name")
            }
            
            if object["callbackId"] as? String != nil {
                callback(object["callbackId"]! as! String)
            }
        }
    }
    
    /**
    Execute Javascript callback
    
    :param: id An unique Id that linked with callback
    */
    func callback(id: String) {
        let evaluateString = "window.rainbowBridge.executeCallback(\(id))"
        self.webView.evaluateJavaScript(evaluateString, completionHandler: nil)
    }
    
    ///
    ///  _   _       _   _              ___        _
    /// | \ | |     | | (_)            / _ \      (_)
    /// |  \| | __ _| |_ ___   _____  / /_\ \_ __  _ ___
    /// | . ` |/ _` | __| \ \ / / _ \ |  _  | '_ \| / __|
    /// | |\  | (_| | |_| |\ V /  __/ | | | | |_) | \__ \
    /// \_| \_/\__,_|\__|_| \_/ \___| \_| |_/ .__/|_|___/
    ///                                     | |
    ///                                     |_|
    
    /**
    Play vibration
    */
    func _playVibration() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
}