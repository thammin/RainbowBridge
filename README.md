# RainbowBridge
A native bridge that using WKScriptMessageHandler to expose native function to JavaScript

Supported Api:
* `AudioServicesPlayAlertSound` - Play vibration

## Requirements:
* ios >= 8.0
* swift 2

## Install with cocoapods
* PodFile
```
platform :ios, '8.0'
use_frameworks!

pod 'RainbowBridge'
```

## Usage
```swift
import RainbowBridge

let webView = RainbowBridge.initWithFrame(self.view.frame)
yourView.addSubview(webView)

let url = NSURL(string: "http://www.github.com")
let req = NSURLRequest(URL:url!)
webView.loadRequest(req)
```

in Javascript
```javascript
// define callback if needed
window.rainbowBridge = {
  callbacks: {
    'onPlayVibration': function(returnedValue) {
      console.log('Vibration played = ', returnedValue); // Vibration played = true
    }
  },
  executeCallback: function(id, returnedValue) {
    this.callbacks[id] && this.callbacks[id](returnedValue);
  }
};

// a helper to stringify JSON object
function createBridgeObjectString(name, id) {
  var obj = {
    wrappedApiName: name,
    callbackId: id
  };


  return JSON.stringify(obj);
}

// create and send the stringified json object to swift
var data = createBridgeObjectString('playVibration', 'onPlayVibration');
window.webkit.messageHandlers.rainbowBridge.postMessage(data);
```

##
