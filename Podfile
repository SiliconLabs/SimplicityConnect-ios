source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.3'

inhibit_all_warnings!
use_frameworks!

def shared_pods
    pod 'ActionSheetPicker-3.0', '~> 2.3.0'
    pod 'ChameleonFramework', '~> 2.1.0'
    pod 'Charts', '~> 3.3.0'
    pod 'Eddystone', :git => 'https://github.com/IntrepidPursuits/eddystone-ios.git', :branch => 'nservidio/add-properties-to-Generic'
    pod 'IP-UIKit-Wisdom', '~> 0.0.10'
    pod 'KVOController', '~> 1.2.0'
    pod 'MZTimerLabel', '~> 0.5.4'
    pod 'PureLayout', '~> 3.1.4'
    pod 'SVProgressHUD', '~> 2.2.5'
    pod 'UICircularProgressRing', '~> 4.1.0'
    pod 'WYPopoverController', '~> 0.2.2'
    pod 'XMLDictionary', '~> 1.4.1'
end

target 'BlueGecko' do
   shared_pods
end

target 'BlueGeckoWithHomeKit' do
   shared_pods
end

target 'WirelessGecko' do
   shared_pods
end
