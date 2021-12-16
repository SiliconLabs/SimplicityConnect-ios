//
//  SILApp.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SILAppType) {
    SILAppTypeConnectedLighting,
    SILAppTypeHealthThermometer,
    SILAppTypeBlinky,
    SILAppTypeRetailBeacon,
    SILAppBluetoothBrowser,
    SILAppTypeHomeKitDebug,
    SILAppTypeRangeTest,
    SILAppTypeAdvertiser,
    SILAppIopTest,
    SILAppTypeGATTConfigurator,
    SILAppTypeThroughput,
    SILAppTypeMotion,
    SILAppTypeEnvironment,
    SILAppTypeWifiCommissioning
};

@interface SILApp : NSObject

@property (assign, nonatomic) SILAppType appType;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *appDescription;
@property (strong, nonatomic) NSDictionary *showcasedProfiles;
@property (strong, nonatomic) NSString *imageName;

+ (NSArray *)demoApps;
+ (NSArray *)developApps;

+ (SILApp *)rangeTestApp;

@end
