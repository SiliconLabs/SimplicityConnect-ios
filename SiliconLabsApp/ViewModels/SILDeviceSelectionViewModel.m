//
//  SILDeviceSelectionViewModel.m
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDeviceSelectionViewModel.h"
#import "SILApp+AttributedProfiles.h"

@implementation SILDeviceSelectionViewModel

- (instancetype)initWithAppType:(SILApp *)app {
    self = [super init];
    self.app = app;
    return self;
}

- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray *)discoveredPeripherals {
    
    self.discoveredCompatibleDevices = [NSMutableArray array];
    self.discoveredOtherDevices = [NSMutableArray array];
    
    for (SILDiscoveredPeripheral *discoveredPeripheral in discoveredPeripherals) {
        if (([discoveredPeripheral isBlueGeckoBeacon])
            || ([discoveredPeripheral isDMPConnectedLightZigbee])
            || ([discoveredPeripheral isDMPConnectedLightProprietary])) {
            [self.discoveredCompatibleDevices addObject:discoveredPeripheral];
        } else {
            [self.discoveredOtherDevices addObject:discoveredPeripheral];
        }
    }
    self.hasDataChanged = YES;
}

- (NSArray *)discoveredDevicesForIndex:(NSInteger)index {
    if (index == 0) {
        return self.discoveredCompatibleDevices;
    } else {
        return self.discoveredOtherDevices;
    }
}

- (NSArray *)availableTabs {
    if (self.app.appType == SILAppTypeHealthThermometer) {
        return @[@"Blue Geckos", @"Other"];
    } else if (self.app.appType == SILAppTypeConnectedLighting) {
        return @[@"Wireless Gecko"];
    } else {
        return @[@""];
    }
}

- (NSString *)selectDeviceString {
    if (self.app.appType == SILAppTypeHealthThermometer) {
        return @"Select a Bluetooth Smart Device";
    } else if (self.app.appType == SILAppTypeConnectedLighting) {
        return @"Select a Wireless Gecko Device";
    } else {
        return @"";
    }
}

- (NSString *)appTitleLabelString {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.app.title : [self.app.title uppercaseString];
}

- (NSString *)appDescriptionString {
    return self.app.appDescription;
}

- (NSAttributedString *)appShowcaseLabelString {
    return [self.app showcasedProfilesAttributedStringWithUserInterfaceIdiom:UI_USER_INTERFACE_IDIOM()];
}

@end
