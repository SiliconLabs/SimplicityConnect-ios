//
//  SILBeacon.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@class EddystoneBeacon ,TLMData;

typedef NS_ENUM(NSInteger, SILBeaconType) {
    SILBeaconTypeUnknown,
    SILBeaconTypeBlueGecko,
    SILBeaconTypeIBeacon,
    SILBeaconTypeAltBeacon,
    SILBeaconTypeEddystone
};

@interface SILBeacon : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *UUIDString;
@property (assign, nonatomic) u_int16_t major;
@property (assign, nonatomic) u_int16_t minor;
@property (assign, nonatomic) int8_t calibrationPower;
@property (strong, nonatomic) NSNumber *txPower;
@property (strong, nonatomic) CLBeacon *beacon; //used by iBeacons
@property (strong, nonatomic) NSNumber *refRSSI; //used by AltBeacons
@property (strong, nonatomic) NSString *beaconNamespace; //used by Eddystone
@property (strong, nonatomic) NSString *instance; //used by Eddystone
@property (strong, nonatomic) NSURL *url; //used by Eddystone
@property (strong, nonatomic) TLMData *tlmData; //used by Eddystone
@property (nonatomic) SILBeaconType type;

+ (instancetype)beaconWithAdvertisment:(NSDictionary *)advertisement name:(NSString *)name error:(NSError **)error;
+ (instancetype)beaconWithIBeacon:(CLBeacon *)beacon;
+ (instancetype)beaconWithEddystone:(EddystoneBeacon *)eddystone;

@end
