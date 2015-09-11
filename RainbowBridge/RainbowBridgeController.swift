//
//  RainbowBridgeController.swift
//  RainbowBridge
//
//  Created by 林 柏楊 on 2015/09/11.
//  Copyright © 2015年 林 柏楊. All rights reserved.
//

import WebKit

class RainbowBridgeController: WKUserContentController, WKScriptMessageHandler {
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print("got message: \(message.body)")
    }
}