Pod::Spec.new do |s|
  s.name        = "SaguaroConnect"
  s.version     = "0.95.0"
  s.summary     = "A swift 3.0 HTTP Session connection wrapper for iOS/OSX applications"
  s.homepage    = "https://github.com/darrylwest/saguaro-connect"
  s.license     = { :type => "MIT" }
  s.authors     = { "darryl.west" => "darryl.west@raincitysoftware.com" }
  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "9.0"
  s.source      = { :git => "https://github.com/darrylwest/saguaro-connect.git", :tag => s.version }
  s.source_files = "SaguaroConnect/*.swift"
  s.dependency 'Just', '~> 0.5.2'
end
