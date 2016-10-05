platform :ios, '9.0'
use_frameworks!

target 'SaguaroConnect' do
  pod 'SaguaroJSON', :git => 'https://github.com/darrylwest/saguaro-json.git'
  pod 'Just', '~> 0.5.2'
end

target 'SaguaroConnectTests' do
  pod 'SaguaroJSON', :git => 'https://github.com/darrylwest/saguaro-json.git'
  pod 'Just', '~> 0.5.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
