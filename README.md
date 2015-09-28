# RainbowBridge
A native bridge that using WKScriptMessageHandler to expose native function to JavaScript

Supported Api:
* [scanMetadata](#scanmetadata) - Scan specified type of metadata using camera
* [playVibration](#playvibration) - Play vibration
* [authenticateTouchId](#authenticatetouchid) - Authenticate with Touch Id
* [joinPeerGroup](#joinpeergroup) - Join a peer group using [PeerKit](https://github.com/jpsim/PeerKit.git)
* [sendEventToPeerGroup](#sendeventtopeergroup) - Send event to peer group using [PeerKit](https://github.com/jpsim/PeerKit.git)
* [leavePeerGroup](#leavepeergroup) - Leave any joined peer group [PeerKit](https://github.com/jpsim/PeerKit.git)
* [downloadAndCache](#downloadandcache) - Download and cache a file from remote url
* [clearCache](#clearcache) - Clear the cached file
* [initializeSound](#initializesound) - Initialize sound with local sound file
* [disposeSound](#disposesound) - Dispose sound instance
* [playSound](#playsound) - Play the sound instance

## Requirements:
* ios >= 8.0
* swift 2
* PeerKit

## Install with cocoapods
* PodFile
```
platform :ios, '8.0'
use_frameworks!

pod 'PeerKit'
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

## Supported Api:

### scanMetadata ###
[ref](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVMetadataMachineReadableCodeObject_Class/#//apple_ref/occ/instp/AVMetadataMachineReadableCodeObject/stringValue)
Scan and detect one-dimensional or two-dimensional barcode.
This will return a callback with detected data as argument

```javascript
{
  wrappedApiName: 'scanMetadata',
  metadataTypes: ['org.iso.QRCode', 'org.gs1.EAN-13'] // array of types to be detected
}
```
MetadataTypes:
```
face
org.iso.Aztec
org.iso.Code128
org.iso.Code39
org.iso.Code39Mod43 
com.intermec.Code93
org.iso.DataMatrix
org.gs1.EAN-13
org.gs1.EAN-8
org.ansi.Interleaved2of5
org.gs1.ITF14
org.iso.PDF417
org.iso.QRCode
org.gs1.UPC-E
```

### playVibration ###
[ref](https://developer.apple.com/library/ios/documentation/AudioToolbox/Reference/SystemSoundServicesReference/#//apple_ref/c/func/AudioServicesPlayAlertSound) -
Plays a system sound as an alert.
```javascript
{
  wrappedApiName: 'playVibration'
}
```

### authenticateTouchId ###
[ref](https://developer.apple.com/library/prerelease/ios/documentation/LocalAuthentication/Reference/LAContext_Class/index.html#//apple_ref/occ/instm/LAContext) -
Request the user to authenticate themselves using personal information such as a fingerprint registered with Touch ID.
```javascript
{
  wrappedApiName: 'authenticateTouchId',
  reason: 'Verify with your finger'
}
```
### joinPeerGroup ###
[ref](https://developer.apple.com/library/prerelease/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework) - 
Join a peer group using [PeerKit](#https://github.com/jpsim/PeerKit.git) as MultipeerConnectivity wrapper.
This support Wi-Fi networks, peer-to-peer Wi-Fi, and Bluetooth personal area networks.
```javascript
{
  wrappedApiName: 'joinPeerGroup',
  peerGroupName: 'group1'
}
```

The callbacks will be execute by 4 type of events.
* onConnecting - when connecting to a peer.
```javascript
{
  type: 'onConnecting',
  myPeerId: <my device display name>,
  targetPeerId: <target device display name>
}
```

* onConnected - when connection to a peer had established.
```javascript
{
  type: 'onConnected',
  myPeerId: <my device display name>,
  targetPeerId: <target device display name>
}
```

* onDisconnected - when connection to a peer had been released.
```javascript
{
  type: 'onDisconnected',
  myPeerId: <my device display name>,
  targetPeerId: <target device display name>
}
```

* [onEvent](#sendeventtopeergroup) - when event received from a peer.
```javascript
{
  type: 'onEvent',
  targetPeerId: <target device display name>,
  event: <unique event name>,
  object: <optional object to be passed by>
}
```

### sendEventToPeerGroup ###
Send a event with optional object data to all connected peers in peer group.
```javascript
{
  wrappedApiName: 'sendEventToPeerGroup',
  event: 'attack',
  object: {
    weapon: 'gun',
    damage: 577
  }
}
```

### leavePeerGroup ###
Leave any joined peer group.
```javascript
{
  wrappedApiName: 'leavePeerGroup'
}
```

### downloadAndCache ###
[ref](https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview) - 
Download file with specified url and cache to the Application Support Directory.
The contents of this directory are backed up by iTunes.
Supported filename only currently.
```javascript
{
  wrappedApiName: 'downloadAndCache',
  url: 'https://www.abc.com/xyz.w4a',
  path: '/xyz.w4a',
  isOverwrite: true
}
```

### clearCache ###
Clear the cached file in the Application Support Directory.
```javascript
{
  wrappedApiName: 'clearCache',
  path: '/xyz.w4a'
}
```

### initializeSound ###
Initialize sound with AVAudioPlayer.
This will return an index value that refer to instance within the sound instances array.
```javascript
{
  wrappedApiName: 'initializeSound',
  file: '/var/mobile/Containers/Data/Application/D411117D-DC60-4A30-8C1D-1AF5304F9F5A/Library/Application Support/xyz.w4a'
}
```

### disposeSound ###
Dispose sound instance.
```javascript
{
  wrappedApiName: 'disposeSound',
  index: 0
}
```

### playSound ###
[ref](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioPlayerClassReference/) - 
Play cached sound instance.
```javascript
{
  wrappedApiName: 'playSound',
  index: 0,
  isRepeat: true
}
```
