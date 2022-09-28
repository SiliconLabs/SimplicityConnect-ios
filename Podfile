source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '12.0'

inhibit_all_warnings!
use_frameworks!

def shared_pods
    pod 'ActionSheetPicker-3.0', '~> 2.3.0'
    pod 'ChameleonFramework', '~> 2.1.0'
    pod 'Charts', '~> 4.1.0'
    pod 'Crashlytics', '~> 3.12.0'
    pod 'Eddystone', :git => 'https://github.com/IntrepidPursuits/eddystone-ios.git', :branch => 'nservidio/add-properties-to-Generic'
    pod 'Fabric', '~> 1.9.0'
    pod 'IP-UIKit-Wisdom', '~> 0.0.10'
    pod 'KVOController', '~> 1.2.0'
    pod 'MZTimerLabel', '~> 0.5.4'
    pod 'PureLayout', '~> 3.1.4'
    pod 'SVProgressHUD', '~> 2.2.5'
    pod 'UICircularProgressRing', '~> 4.1.0'
    pod 'WYPopoverController', :git => 'https://github.com/sammcewan/WYPopoverController.git'
    pod 'XMLDictionary', '~> 1.4.1'
    pod 'Realm', '~> 4.3.2'
    pod 'RealmSwift'
    pod 'AEXML'
    pod 'RxSwift',    '~> 6.2.0'
    pod 'RxCocoa',    '~> 6.2.0'
end

def test_pods
  pod 'Quick'
  pod 'Nimble'
  pod 'OCMock'
  pod 'MockingbirdFramework', '~> 0.20'
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

target 'BlueGeckoTests' do
  shared_pods
  test_pods
end
