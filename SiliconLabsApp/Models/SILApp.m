//
//  SILApp.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILApp.h"
#import "UIImage+SILImages.h"

@implementation SILApp

+ (NSArray *)demoApps {
    return @[
                [self healthThermometerApp],
                [self connectedLightningApp],
                [self rangeTestApp],
                [self blinkyApp],
                [self throughputApp],
                [self motionApp],
                [self environmentApp],
                [self wifiCommissioningApp]
            ];
}

+ (NSArray *)developApps {
    return @[
                [self bluetoothBrowserApp],
                [self advertiserApp],
                [self gattConfiguratorApp],
                [self iopTestApp],
                [self rssiGraph]
            ];
}

+ (SILApp *)connectedLightningApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeConnectedLighting
                                     title:@"Connected Lighting"
                               description:@"Control a Dynamic Multiprotocol application of connected lights and switches."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeConnectedLighting];
}

+ (SILApp *)healthThermometerApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeHealthThermometer
                                     title:@"Health Thermometer"
                               description:@"View readings from the health thermometer service."
                         showcasedProfiles:@{ @"HTP" : @"­Health Thermometer Profile" }
                                 imageName:SILImageNameHomeThermometer];
}

+ (SILApp *)blinkyApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeBlinky
                                     title:@"Blinky"
                               description:@"Control LED and receive button presses on a Silabs kit."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeBlinky];
}

+ (SILApp *)bluetoothBeaconingApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeRetailBeacon
                              title:@"Bluetooth Beaconing"
                        description:@"Identify and detect Apple iBeacons and Google EddyStone beacons."
                  showcasedProfiles:@{}
                          imageName:SILImageNameHomeHelp];
}

+ (SILApp *)bluetoothBrowserApp {
    return [[SILApp alloc] initWithAppType:SILAppBluetoothBrowser
                                     title:@"Browser"
                               description:@"View info about nearby devices and their properties."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeDebug];
}

+ (SILApp *)homekitApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeHomeKitDebug
                                     title:@"HomeKit Browser"
                               description:@"View info about nearby HomeKit devices and their properties."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeKitDebug];
}

+ (SILApp *)rangeTestApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeRangeTest
                                     title:@"Range Test"
                               description:@"Evaluate the link budget and range of EFR32."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeRangeTestDemo];
}

+ (SILApp *)advertiserApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeAdvertiser
                                     title:@"Advertiser"
                               description:@"Utilize this device as a Bluetooth Low Energy peripheral."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeAdvertiser];
}

+ (SILApp *)rssiGraph {
    return [[SILApp alloc] initWithAppType:SILAppTypeRSSIGraph
                                     title:@"RSSI Graph"
                               description:@"Draw a plot with RSSI data from discovered devices."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeRangeTestDemo];
}

+ (SILApp *)iopTestApp {
    return [[SILApp alloc] initWithAppType:SILAppIopTest
                                     title:@"Interoperability Test"
                               description:@"Exercise common Bluetooth operations with Silicon Labs hardware and software."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeIOPTester];
}

+ (SILApp *)gattConfiguratorApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeGATTConfigurator
                                     title:@"GATT Configurator"
                               description:@"Allows you to create a local GATT database."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeGattConfigurator];
}

+ (SILApp *)throughputApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeThroughput
                                     title:@"Throughput"
                               description:@"Measure throughput between the mobile device and EFR32."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeThroughput];
}

+ (SILApp *)motionApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeMotion
                                     title:@"Motion"
                               description:@"Control a 3D render of a dev kit."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeMotion];
}

+ (SILApp *)environmentApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeEnvironment
                                     title:@"Environment"
                               description:@"Read and display data from the dev kit sensors."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeEnvironment];
}

+ (SILApp *)wifiCommissioningApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiCommissioning
                                     title:@"Wi-Fi Commissioning"
                               description:@"Wi-Fi commissioning over BLE."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWifiCommissioning];
}

- (instancetype)initWithAppType:(SILAppType)appType
                           title:(NSString *)title
                     description:(NSString *)description
               showcasedProfiles:(NSDictionary *)showcasedProfiles
                       imageName:(NSString *)imageName {
    self = [super init];
    if (self) {
        self.appType = appType;
        self.title = title;
        self.appDescription = description;
        self.showcasedProfiles = showcasedProfiles;
        self.imageName = imageName;
    }
    return self;
}

@end
