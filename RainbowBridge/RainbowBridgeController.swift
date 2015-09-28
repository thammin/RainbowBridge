//
//  RainbowBridgeController.swift
//  RainbowBridge
//
//  Created by 林 柏楊 on 2015/09/11.
//  Copyright © 2015年 林 柏楊. All rights reserved.
//

import WebKit
import PeerKit
import AudioToolbox
import AVFoundation
import LocalAuthentication
import MultipeerConnectivity

class RainbowBridgeController: WKUserContentController {
    
    // reference to webView
    var webView: WKWebView! = nil
    
    // some references
    /// code reader references
    var captureOutputCallbacks = Array<(String -> ())>()
    var captureSession: AVCaptureSession?
    var videoLayer: AVCaptureVideoPreviewLayer?
    
    /**
    Set the target webView as reference
    
    :param: view Target's view
    */
    func setTargetView(view: WKWebView) {
        self.webView = view
    }
    
    /**
    Native api wrapper
    TODO: add parameters as arguments
    
    :param: withObject JSON object
    */
    func callNativeApi(withObject object: AnyObject) {
        if object["wrappedApiName"] as? String != nil {
            
            // exeucte Javascript callback if callbackId is passed
            func cb(returnedValue: String?) {
                if object["callbackId"] as? String != nil {
                    callback(object["callbackId"]! as! String, returnedValue: returnedValue)
                }
            }
            
            let wrappedApiName = object["wrappedApiName"]! as! String
            switch wrappedApiName {
            case "joinPeerGroup":
                self._joinPeerGroup(object["peerGroupName"]! as! String, cb: { cb($0) })
            case "sendEventToPeerGroup":
                self._sendEventToPeerGroup(object["event"]! as! String, object: object["object"]! as AnyObject?, cb: { cb($0) })
            case "leavePeerGroup":
                self._leavePeerGroup({ cb($0) })
            case "downloadAndCache":
                self._downloadAndCache(object["url"]! as! String, path: object["path"]! as! String, isOverwrite: object["isOverwrite"]! as! Bool, cb: { cb($0) })
            case "clearCache":
                self._clearCache(object["path"]! as! String, cb: { cb($0) })
            case "scanMetadata":
                self._scanMetadata(object["metadataTypes"]! as! Array, cb: { cb($0) })
            case "playVibration":
                self._playVibration({ cb($0) })
            case "authenticateTouchId":
                self._authenticateTouchId(reason: object["reason"]! as! String, cb: { cb($0) })
            default:
                print("Invalid wrapped api name")
            }
        }
    }
    
    /**
    Execute Javascript callback
    
    :param: id An unique Id that linked with callback
    :param: returnedValue A String value to be return to Javascript callback
    */
    func callback(id: String, returnedValue: String?) {
        let evaluateString = "window.rainbowBridge.executeCallback('\(id)', \(returnedValue! as String))"
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
    Join a peer group with specified name
    
    :param: peerGroupName unique name of the group
    :param: cb Javascript callback
    */
    func _joinPeerGroup(peerGroupName: String, cb: String -> ()) {
        // when connecting to a peer
        PeerKit.onConnecting = {
            (myPeerId, targetPeerId) -> () in
            cb("{ type: 'onConnecting', myPeerId: '\(myPeerId.displayName)', targetPeerId: '\(targetPeerId.displayName)'}")
        }
        
        // when connection to a peer had established
        PeerKit.onConnect = {
            (myPeerId, targetPeerId) -> () in
            cb("{ type: 'onConnected', myPeerId: '\(myPeerId.displayName)', targetPeerId: '\(targetPeerId.displayName)'}")
        }
        
        // when connection to a peer had been released
        PeerKit.onDisconnect = {
            (myPeerId, targetPeerId) -> () in
            cb("{ type: 'onDisconnected', myPeerId: '\(myPeerId.displayName)', targetPeerId: '\(targetPeerId.displayName)'}")
        }
        
        // when event received from a peer
        PeerKit.onEvent = {
            (targetPeerId, event, object) -> () in
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(object!, options: NSJSONWritingOptions.PrettyPrinted)
                let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
                cb("{ type: 'onEvent', targetPeerId: '\(targetPeerId)', event: '\(event)', object: \(jsonString)}")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        PeerKit.transceiver = Transceiver(displayName: PeerKit.myName)
        PeerKit.transceive(peerGroupName)
    }
    
    /**
    Send event with optional object to peer group
    
    :param: event unique event name
    :param: object optional object
    :param: cb Javascript callback
    */
    func _sendEventToPeerGroup(event: String, object: AnyObject?, cb: String -> ()) {
        let peers = PeerKit.session?.connectedPeers as [MCPeerID]? ?? []
        PeerKit.sendEvent(event, object: object, toPeers: peers)
        
        let peersJson = peers.map {
            (let peer) -> String in
            return peer.displayName
        }
        cb("{ connectedPeers: \(peersJson)}")
    }
    
    /**
    Leave any peer group we had joined
    
    :param: cb Javascript callback
    */
    func _leavePeerGroup(cb: String -> ()) {
        PeerKit.stopTransceiving()
        cb("true")
    }
    
    /**
    Download file with specified url and cache to the Application Support Directory
    
    :param: url file's url
    :param: path relative path to be save in Application Support Directory
    :param: isOverwrite allow to overwrite if same file is exist, disable this attribute will skip the download
    :param: cb Javascript callback
    */
    func _downloadAndCache(url: String, path: String, isOverwrite: Bool, cb: String -> ()) {
        let fileManager = NSFileManager.defaultManager()
        let dir = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).first
        let file = dir?.stringByAppendingString("/" + NSBundle.mainBundle().bundleIdentifier! + path)
        
        // create Application Support directory if not existed
        if (fileManager.fileExistsAtPath(dir!)) {
            do {
                try fileManager.createDirectoryAtPath(dir!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        // skip download if file is already existed
        if (fileManager.fileExistsAtPath(file!) && !isOverwrite) {
            cb("'The `\(file!)` is already existed.'")
            return
        }
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let request = NSURLRequest(URL: NSURL(string: url)!)
        
        let downloadTask = session.downloadTaskWithRequest(request, completionHandler: {
            (tempUrl, res, err) -> Void in
            do {
                let data = try NSData(contentsOfURL: tempUrl!, options: NSDataReadingOptions.DataReadingMappedAlways)
                fileManager.createFileAtPath(file!, contents: data, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            cb("'`\(file!)` had been downloaded sucessful.'")
        })
        
        downloadTask.resume()
    }
    
    /**
    Clear the cached file in the Application Support Directory
    
    :param: path relative path to be save in Application Support Directory
    :param: cb Javascript callback
    */
    func _clearCache(path: String, cb: String -> ()) {
        let fileManager = NSFileManager.defaultManager()
        let dir = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).first
        let file = dir?.stringByAppendingString("/" + NSBundle.mainBundle().bundleIdentifier! + path)
    
        do {
            try fileManager.removeItemAtPath(file!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        cb("'`\(file!)` had been cleared.'")
    }
    
    /**
    Scan specified type of metadata using camera
    
    
    :param: metadataTypes code types
    :param: cb JAvascript callback
    */
    func _scanMetadata(metadataTypes: [String], cb: String -> ()) {
        self.captureSession = AVCaptureSession()
        
        var backCamera: AVCaptureDevice!
        for device in AVCaptureDevice.devices() {
            if device.position == AVCaptureDevicePosition.Back {
                backCamera = device as! AVCaptureDevice
            }
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: backCamera)
            if self.captureSession?.canAddInput(videoInput) != nil {
                self.captureSession?.addInput(videoInput)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let metadataOutput: AVCaptureMetadataOutput! = AVCaptureMetadataOutput()
        if self.captureSession?.canAddOutput(metadataOutput) != nil {
            self.captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            metadataOutput.metadataObjectTypes = metadataTypes
        }
        
        self.videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoLayer!.frame = self.webView.bounds
        self.videoLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.webView.layer.addSublayer(self.videoLayer!)
        self.captureOutputCallbacks.append(cb)
        
        self.captureSession?.startRunning()
    }
    
    /**
    Play vibration
    
    :param: cb Javascript callback
    */
    func _playVibration(cb: String -> ()) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        cb("true")
    }
    
    /**
    Touch id authentication
    
    :param: reason message to be viewed when authentication prompted up
    :param: cb Javascript callback
    */
    func _authenticateTouchId(reason reason: String, cb: String -> ()) {
        let authContext = LAContext()
        if authContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            authContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason,
                reply: {(success: Bool, error: NSError?) -> Void in
                    cb(String(stringInterpolationSegment: success))
            })
        }
    }
}

extension RainbowBridgeController: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if message.body is NSNull {
            print("Null is not allowed.")
            return
        }
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(message.body.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.MutableContainers)
            self.callNativeApi(withObject: json)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

extension RainbowBridgeController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects.count > 0 {
            let data: AVMetadataMachineReadableCodeObject  = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.videoLayer?.removeFromSuperlayer()
            self.videoLayer = nil
            
            let jsonString = "{type:'\(data.type)', stringValue:'\(data.stringValue)'}"
            if self.captureOutputCallbacks.count > 0 {
                self.captureOutputCallbacks[0](jsonString)
                // add print to remove the `Expression resolves to an unused function` warning
                print(self.captureOutputCallbacks.removeAtIndex(0))
            }
        }
    }
}