source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '12.0'

inhibit_all_warnings!
use_frameworks!

def shared_pods
    pod 'ActionSheetPicker-3.0', '~> 2.3.0'
    pod 'ChameleonFramework', '~> 2.1.0'
    pod 'Charts', '~> 4.1.0'
    pod 'Crashlytics', '~> 3.12.0'
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
    pod 'Introspect'
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

post_install do |installer|
	installer.generated_projects.each do |project|
		project.targets.each do |target|
			target.build_configurations.each do |config|
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
         		end

			shell_script_path = "Pods/Target Support Files/#{target.name}/#{target.name}-frameworks.sh"
			if File::exists?(shell_script_path)
		 		shell_script_input_lines = File.readlines(shell_script_path)
		 		shell_script_output_lines = shell_script_input_lines.map { |line| line.sub("source=\"$(readlink \"${source}\")\"", "source=\"$(readlink -f \"${source}\")\"") }
		 		File.open(shell_script_path, 'w') do |f|
			        	shell_script_output_lines.each do |line|
			        		f.write line
					end
        	 		end
	 		end
    		end
  	end
end
