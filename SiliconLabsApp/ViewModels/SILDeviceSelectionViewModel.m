//
//  SILDeviceSelectionViewModel.m
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDeviceSelectionViewModel.h"
#import "SILApp+AttributedProfiles.h"

CGFloat const SILDeviceSelectionViewModelRSSIThreshold = 1.0;

@implementation SILDeviceSelectionViewModel

- (instancetype)initWithAppType:(SILApp *)app {
    self = [super init];
    self.app = app;
    self.discoveredDevices = @[];
    self.filter = ^BOOL(SILDiscoveredPeripheral* peripheral) {
        for (CBUUID * cbuuid in [SILDeviceSelectionViewModel serviceListForAppType:app.appType]) {
            if ([peripheral.advertisedServiceUUIDs containsObject:cbuuid]) {
                return YES;
            }
        }
        return NO;
    };
    
    return self;
}

- (instancetype)initWithAppType:(SILApp *)app withFilter:(DiscoveredPeripheralFilter)filter {
    self = [super init];
    self.app = app;
    self.discoveredDevices = @[];
    self.filter = filter;
    
    return self;
}

+ (NSArray*)serviceListForAppType:(SILAppType)appType {
    NSArray *serviceUUIDs = @[];
    switch (appType) {
        case SILAppTypeHealthThermometer:
            serviceUUIDs = @[
                             [CBUUID UUIDWithString:SILServiceNumberHealthThermometer],
                             [CBUUID UUIDWithString:@"FFF0"], // Temporarily added to support connecting to 3rd Party Thermometer...
                             ];
            break;
        case SILAppTypeConnectedLighting:
            serviceUUIDs = @[[CBUUID UUIDWithString:SILServiceNumberConnectedLightingConnect],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingProprietary],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingThread],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingZigbee],];
            break;
            
        case SILAppTypeESLDemo:
            serviceUUIDs = @[
                             [CBUUID UUIDWithString:SILServiceNumberESLServiceControl],
                             ];
            break;
            
        default:
            break;
    }
    return serviceUUIDs;
}

- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    self.discoveredDevices = [self sortedDiscoveredDevices:[self removeDevicesNotMatchRequirements:discoveredPeripherals]];
    self.hasDataChanged = YES;
}

- (NSArray<SILDiscoveredPeripheral*>*)removeDevicesNotMatchRequirements:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    NSPredicate* filterPredicate = [NSPredicate predicateWithBlock:^BOOL(SILDiscoveredPeripheral* evaluatedObject, NSDictionary<NSString *,id>* bindings) {
        return evaluatedObject.isConnectable && self.filter(evaluatedObject);
    }];
    
    return [discoveredPeripherals filteredArrayUsingPredicate:filterPredicate];
}

- (NSArray<SILDiscoveredPeripheral*>*)sortedDiscoveredDevices:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    return [discoveredPeripherals sortedArrayUsingComparator:^NSComparisonResult(SILDiscoveredPeripheral* obj1, SILDiscoveredPeripheral* obj2) {
        return [self compareFirstPeripheral:obj1 withSecondPeripheral:obj2];
    }];
}

- (NSInteger)compareFirstPeripheral:(SILDiscoveredPeripheral*)obj1 withSecondPeripheral:(SILDiscoveredPeripheral*)obj2 {
    NSString *nameOfObj1 = obj1.advertisedLocalName;
    NSString *nameOfObj2 = obj2.advertisedLocalName;
    
    if (nameOfObj1 != nil) {
        return [nameOfObj1 localizedCaseInsensitiveCompare:nameOfObj2];
    } else if (nameOfObj2 != nil) {
        return [nameOfObj2 localizedCaseInsensitiveCompare:nameOfObj1];
    } else {
        return NSOrderedSame;
    }
}

- (NSString *)selectDeviceString {
    return @"Select a BLE Device";
}

- (NSString *)selectDeviceInfoString {
    switch (self.app.appType) {
        case SILAppTypeHealthThermometer:
            return @"A circuit board (SoC) must be connected and running \"Bluetooth - SoC Thermometer\" firmware.";
        case SILAppTypeThroughput:
            return @"A circuit board (SoC) must be connected and running \"Bluetooth - SoC Throughput\" firmware.";
        case SILAppIopTest:
            return @"A circuit board (SoC) must be connected and running \"Bluetooth - SoC Interoperability Test\" firmware.";
        case SILAppTypeBlinky:
            return @"A circuit board (SoC) must be connected and running \"Bluetooth - SoC Blinky\" firmware or firmware with a title containing \"Bluetooth - SoC Dev Kit\" or \"Bluetooth - SoC Thunderboard\".";
        case SILAppTypeWifiCommissioning:
            return @"A circuit board (SoC) and the evaluation board (EVK) must be connected and running proper firmwares. See the documentation, tutorial and GitHub for more information.";
        case SILAppTypeConnectedLighting:
            return @"A circuit board (SoC) must be connected and running \"Bluetooth RAIL DMP - SoC Light Standard\" or \"Connect Bluetooth DMP - SoC Light\" firmware.";
        case SILAppTypeRangeTest:
            return @"A circuit board (SoC) must be connected and running \"RAIL Bluetooth DMP - SoC Range Test\" firmware.";
        case SILAppTypeMotion:
        case SILAppTypeEnvironment:
            return @"A circuit board (SoC) must be connected and running firmware with a title containing \"Bluetooth - SoC Dev Kit\" or \"Bluetooth - SoC Thunderboard\".";
        case SILAppTypeESLDemo:
            return @"A circuit board (SoC) must be connected and running firmware with a title containing \"Bluetooth - SoC NCP ESL Demo\".";
        case SILAppTypeWifiSensor:
            return @"1. The SoC and evaluation board (EVK) must be connected and running the correct firmware.\n2. The Wi-Fi network on your mobile device should match the Wi-Fi network used for the sensor device's commissioning.\n3. Enable your phone's local network to access sensor data.";
        default:
            return @"";
    }
}

- (NSDictionary *)selectDeviceHyperlinks {
    NSMutableDictionary *links = [NSMutableDictionary dictionary];
    switch (self.app.appType) {
        case SILAppTypeWifiCommissioning:
            [links setObject: @"https://docs.silabs.com/rs9116-wiseconnect/latest/wifibt-wc-getting-started-with-pc/update-evk-firmware"  forKey: @"documentation"];
            [links setObject: @"https://docs.silabs.com/rs9116-wiseconnect/latest/wifibt-wc-getting-started-with-efx32"  forKey: @"tutorial"];
            [links setObject: @"https://github.com/SiliconLabs/wiseconnect-wifi-bt-sdk/tree/master/examples/snippets/wlan_ble/wlan_station_ble_provisioning"  forKey: @"GitHub"];
            break;
        default:
            break;
    }
    return [links copy];
}

@end
