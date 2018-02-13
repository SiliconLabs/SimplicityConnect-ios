source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'

inhibit_all_warnings!
use_frameworks!

def shared_pods
    pod 'Crashlytics'
    pod 'Eddystone', :git => 'https://github.com/IntrepidPursuits/eddystone-ios.git', :branch => 'nservidio/add-properties-to-Generic'
    pod 'Fabric'
    pod 'IP-UIKit-Wisdom'
    pod 'KVOController'
    pod 'MZTimerLabel'
    pod 'PureLayout', '~> 3.0'
    pod 'SVProgressHUD'
    pod 'UICircularProgressRing'
    pod 'WYPopoverController', '~> 0.2.0'
    pod 'XMLDictionary'
end

target 'SiliconLabsApp' do
   shared_pods
end

target 'SiliconLabsAppWithoutHomeKit' do
   shared_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
