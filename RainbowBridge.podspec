Pod::Spec.new do |s|
  s.name         = "RainbowBridge"
  s.version      = "0.0.1"
  s.summary      = "A native bridge that using WKScriptMessageHandler to expose native function to JavaScript"
  s.homepage     = "https://github.com/thammin/RainbowBridge"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "thammin" => "thammin@live.co.uk" }
  s.source       = { :git => "https://github.com/thammin/RainbowBridge.git", :tag => s.version }
  s.source_files  = "RainbowBridge/*.{h,swift}"
  s.ios.deployment_target = "8.0"
  s.requires_arc = true
end