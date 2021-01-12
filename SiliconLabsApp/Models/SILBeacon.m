//
//  SILBeacon.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "SILBeacon.h"
#import "NSError+SILHelpers.h"
#import "SILConstants.h"

uint16_t const kBlueGeckoAltBeaconCode = 0xBEAC;
uint16_t const kSilabsMfgId = 0x0047;
uint16_t const kEddystoneBeaconCode = 0xFEAA;

NSString * const SILBeaconUnspecified = @"Unspecified";
NSString * const SILBeaconIBeacon = @"iBeacon";
NSString * const SILBeaconAltBeacon = @"AltBeacon";
NSString * const SILBeaconEddystone = @"Eddystone";

@implementation SILBeacon

+ (instancetype)beaconWithAdvertisment:(NSDictionary *)advertisement name:(NSString *)name error:(NSError **)error {
    SILBeacon* beacon;
    NSNumber *txPower = advertisement[CBAdvertisementDataTxPowerLevelKey] ? advertisement[CBAdvertisementDataTxPowerLevelKey] : @(SILConstantsTxPowerDefault);
    NSData *manufacturerData = advertisement[CBAdvertisementDataManufacturerDataKey];

    if (manufacturerData.length < 25) {
        if (error != NULL) {
            *error = [NSError sil_errorWithCode:SILErrorCodeInvalidDataFormat userInfo:nil];
        }
        return nil;
    }

    uint8_t *dataPointer = (uint8_t *)manufacturerData.bytes;
    uint16_t mfgId = *(uint16_t *)(&dataPointer[0]);
    uint16_t beaconCode = CFSwapInt16BigToHost(*(uint16_t *)(&dataPointer[2])); //This needs to get swapped and Idk why
    if (beaconCode == kBlueGeckoAltBeaconCode && mfgId == kSilabsMfgId) {
        beacon = [SILBeacon altBeaconWithManufacturingData:manufacturerData txPower:txPower error:error];
        beacon.name = SILBeaconAltBeacon;
    } else {
        beacon = [SILBeacon bgBeaconWithManufacturingData:manufacturerData error:error];
        beacon.name = SILBeaconUnspecified;
    }
    beacon.txPower = txPower;
    return beacon;
}

+ (instancetype)beaconWithIBeacon:(CLBeacon *)iBeacon {
    if (!iBeacon) {
        return nil;
    }

    SILBeacon *beacon = [[SILBeacon alloc] init];

    beacon.UUIDString = iBeacon.proximityUUID.UUIDString;
    beacon.major = [iBeacon.major intValue];
    beacon.minor = [iBeacon.minor intValue];
    beacon.beacon = iBeacon;
    beacon.type = SILBeaconTypeIBeacon;
    beacon.name = [iBeacon.minor stringValue];

    return beacon;
}

+ (instancetype)beaconWithEddystone:(NSData *)eddystoneServiceData {
    SILBeacon* beacon = [[SILBeacon alloc] init];
    
    beacon.name = @"Eddystone";
    beacon.type = SILBeaconTypeEddystone;
    beacon.eddystoneData = eddystoneServiceData;
    
    uint8_t *dataPointer = (uint8_t *)eddystoneServiceData.bytes;
    
    if (dataPointer == nil) {
        beacon.eddystoneBeaconType = SILEddystoneBeaconTypeUnspecified;
        return beacon;
    }
    
    switch (dataPointer[0]) {
        case 0x00:
            beacon.eddystoneBeaconType = SILEddystoneBeaconTypeUID;
            break;
        case 0x10:
            beacon.eddystoneBeaconType = SILEddystoneBeaconTypeURL;
            break;
        case 0x20:
            if (dataPointer[1] == 0x00) {
                beacon.eddystoneBeaconType = SILEddystoneBeaconTypeTLMUnencrypted;
            } else if (dataPointer[1] == 0x01) {
                beacon.eddystoneBeaconType = SILEddystoneBeaconTypeTLMEncrypted;
            } else {
                beacon.eddystoneBeaconType = SILEddystoneBeaconTypeUnspecified;
            }
            break;
        case 0x30:
            beacon.eddystoneBeaconType = SILEddystoneBeaconTypeEID;
            break;
        default:
            beacon.eddystoneBeaconType = SILEddystoneBeaconTypeUnspecified;
            break;
    }

    return beacon;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, identifier = %@, major = %d, minor = %d, tx_power = %d, namespace = %@, instance = %@, url = %@>",
            [self class],
            self,
            self.UUIDString,
            self.major,
            self.minor,
            self.calibrationPower,
            self.beaconNamespace,
            self.instance,
            self.url
            ];
}

#pragma mark - Decoding Beacon Formats

+ (SILBeacon *)bgBeaconWithManufacturingData:(NSData *)data error:(NSError **)error {
    SILBeacon *beacon = [[SILBeacon alloc] init];

    uint8_t *dataPointer = (uint8_t *)data.bytes;

    // Skip company identifier
    dataPointer += 2;

    BOOL isDataFromBeacon = dataPointer[0] == 0x02;
    if(!isDataFromBeacon) {
        if (error != NULL) {
            *error = [NSError sil_errorWithCode:SILErrorCodeInvalidDataFormat userInfo:nil];
        }
        return nil;
    }
    dataPointer++;

    // Skip Advertisement Length
    dataPointer++;

    NSMutableString *mutableUUIDString = [NSMutableString string];
    for (int i = 0; i < 16; i++) {
        [mutableUUIDString appendFormat:@"%02x", dataPointer[0]];
        dataPointer++;
    }
    beacon.UUIDString = [mutableUUIDString copy];

    beacon.major = CFSwapInt16LittleToHost(*(uint16_t *)(&dataPointer[0]));
    dataPointer += 2;

    beacon.minor = CFSwapInt16LittleToHost(*(uint16_t *)(&dataPointer[0]));
    dataPointer += 2;

    beacon.calibrationPower = dataPointer[0];

   // beacon.type = @"Blue Gecko";

    return beacon;
}

+ (SILBeacon *)altBeaconWithManufacturingData:(NSData *)data txPower:(NSNumber *)txPower error:(NSError **)error {
    SILBeacon *beacon = [[SILBeacon alloc] init];

    if (data.length < 25) {
        if (error != NULL) {
            *error = [NSError sil_errorWithCode:SILErrorCodeInvalidDataFormat userInfo:nil];
        }
        return nil;
    }

    uint8_t *dataPointer = (uint8_t *)data.bytes;
    NSMutableString *manufactuterIDString = [[NSMutableString alloc] initWithString:@"0x"];
    [manufactuterIDString appendFormat:@"%02hhX", dataPointer[1]];
    [manufactuterIDString appendFormat:@"%02hhX", dataPointer[0]];
    beacon.manufacturerID = [manufactuterIDString copy];
    
    dataPointer += 4; //skip beacon code

    NSMutableString *mutableUUIDString = [[NSMutableString alloc] initWithString:@"0x"];
    for (int i = 0; i < 20; i++) {
        [mutableUUIDString appendFormat:@"%02hhX", dataPointer[0]];
        dataPointer++;
    }
    beacon.UUIDString = [mutableUUIDString copy];
    beacon.calibrationPower = (int8_t)[txPower intValue];
    beacon.type = SILBeaconTypeAltBeacon;
    beacon.refRSSI = @((int8_t)(dataPointer[0]));
    return beacon;
}

@end
