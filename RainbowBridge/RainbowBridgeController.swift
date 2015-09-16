//
//  RainbowBridgeController.swift
//  RainbowBridge
//
//  Created by 林 柏楊 on 2015/09/11.
//  Copyright © 2015年 林 柏楊. All rights reserved.
//

import WebKit
import AudioToolbox
import AVFoundation
import LocalAuthentication

class RainbowBridgeController: WKUserContentController, WKScriptMessageHandler, AVCaptureMetadataOutputObjectsDelegate {
    
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
            
            // exeucte Javascript callback if callbackId is passed
            func cb(returnedValue: String?) {
                if object["callbackId"] as? String != nil {
                    callback(object["callbackId"]! as! String, returnedValue: returnedValue)
                }
            }
            
            let wrappedApiName = object["wrappedApiName"]! as! String
            switch wrappedApiName {
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
        let evaluateString = "window.rainbowBridge.executeCallback(\(id), \(returnedValue! as String))"
        self.webView.evaluateJavaScript(evaluateString, completionHandler: nil)
    }
    
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