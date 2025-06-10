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
                [self wifiCommissioningApp],
                [self eslDemoApp],
                [self matterDemoApp],
                [self WifiOTADemoApp],
                [self WifiSensorDemoApp],
                [self WifiSensorThroughput],
                [self WifiProvisionDemoApp],
                [self AWSIOTDemoApp]
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

+ (SILApp *)rangeTestApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeRangeTest
                                     title:@"Range Test"
                               description:@"Evaluate the link budget and range of EFR32."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeRangeTestDemo];
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

+ (SILApp *)iopTestApp {
    return [[SILApp alloc] initWithAppType:SILAppIopTest
                                     title:@"Interoperability Test"
                               description:@"Exercise common Bluetooth operations with Silicon Labs hardware and software."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeIOPTester];
}

+ (SILApp *)wifiCommissioningApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiCommissioning
                                     title:@"Wi-Fi Commissioning"
                               description:@"Wi-Fi commissioning over BLE."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWifiCommissioning];
}

+ (SILApp *)eslDemoApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeESLDemo
                                     title:@"ESL Demo"
                               description:@"Add/commission ESL tags by scanning its QR code and control them from the UI."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeESLDemo];
}

+ (SILApp *)matterDemoApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeMatterDemo
                                     title:@"Matter Demo"
                               description:@"Add/commission Matter tags by scanning its QR code and control them from the UI."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeMatterDemo];
}

+ (SILApp *)WifiOTADemoApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiOTA
                                     title:@"Wi-Fi OTA Demo"
                               description:@"Control OTA Firmware update over Wi-Fi."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWifiOtaDemo];
}
+ (SILApp *)WifiSensorDemoApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiSensor
                                     title:@"Wi-Fi Sensors"
                               description:@"Read and display sensor data from the dev kit sensors."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWiFiSensor];
}

+ (SILApp *)WifiSensorThroughput {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiThroughput
                                     title:@"Wi-Fi Throughput"
                               description:@"Measure Wi-Fi throughput between the mobile device and SiW917."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWiFiThroughput];
}
//Provisioning over Wi-Fi
+ (SILApp *)WifiProvisionDemoApp {
    return [[SILApp alloc] initWithAppType:SILAppTypeWifiProvision
                                     title:@"Wi-Fi Provisioning"
                               description:@"Provisioning over Wi-Fi."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeWifiProvision];
}

+ (SILApp *)AWSIOTDemoApp{
    return [[SILApp alloc] initWithAppType:SILAppTypeAWSIOT
                                     title:@"AWS IoT"
                               description:@"Add/commission a device and read or control it over AWS IoT Cloud."
                         showcasedProfiles:@{}
                                 imageName:SILImageNameHomeAWSIoT];
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
