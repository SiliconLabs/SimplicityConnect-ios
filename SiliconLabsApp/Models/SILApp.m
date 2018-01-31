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

+ (NSArray *)allApps {
    NSMutableArray *allApps = [[NSMutableArray alloc] init];
#if WIRELESS
    return @[[self connectedLightningApp],
             [self bluetoothBeaconingApp],
             [self bluetoothBrowserApp]];
#else
    allApps = [@[[self healthThermometerApp],
                 [self bluetoothBeaconingApp],
                 [self keyFobApp],
                 [self bluetoothBrowserApp]] mutableCopy];
#if ENABLE_HOMEKIT
    [allApps addObject:[self homekitApp]];
#endif
    return [NSArray arrayWithArray:allApps];
#endif
}

+ (SILApp *)connectedLightningApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeConnectedLighting
                                     title:@"Connected Lighting Demo"
                               description:@"Dynamic multiprotocol application showcasing simultaneous operation of Bluetooth plus Zigbee or Proprietary Sub-GHz on the Wireless Gecko SoC"
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeConnectedLighting];
}

+ (SILApp *)healthThermometerApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeHealthThermometer
                                     title:@"Health Thermometer"
                               description:@"View current and saved thermometer readings."
                         showcasedProfiles:@{ @"HTP" : @"­Health Thermometer Profile" }
                                 imageName:SILImageNameHomeThermometer];
}

+ (SILApp *)bluetoothBeaconingApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeRetailBeacon
                              title:@"Bluetooth Beaconing"
                        description:@"Identify and detect Apple iBeacons and Google EddyStone beacons."
                  showcasedProfiles:@{}
                          imageName:SILImageNameHomeRetailBeacon];
}

+ (SILApp *)keyFobApp {
    return  [[SILApp alloc] initWithAppType:SILAppTypeKeyFob
                                      title:@"Key Fobs"
                                description:@"Detect and find Key Fobs via intelligent alerts."
                          showcasedProfiles:@{ @"FMP" : @"­Find Me"}
                                  imageName:SILImageNameHomeKeyFOB];
}

+ (SILApp *)bluetoothBrowserApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeDebug
                                     title:@"Bluetooth Browser"
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
