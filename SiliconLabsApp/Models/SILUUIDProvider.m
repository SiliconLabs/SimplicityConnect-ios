//
//  SILUUIDProvider.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILUUIDProvider.h"

NSString * const kSILOtaServiceUUIDString = @"1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0";
NSString * const kSILOtaCharacteristicDataUUIDString = @"984227f3-34fc-4045-a5d0-2c581f81a153";
NSString * const kSILOtaCharacteristicControlUUIDString = @"f7bf3564-fb6d-4e53-88a4-5e37e0326063";
NSString * const kSILOtaCharacteristicFirmwareVersionUUIDString = @"4f4a2368-8cca-451e-bfff-cf0e2ee23e9f";
NSString * const kSILOtaCharacteristicOtaVersionUUIDString = @"4cc07bcf-0868-4b32-9dad-ba4cc41e5316";
static NSDictionary *kSILOtaServiceAndCharacteristicNamesForUUIDs = nil;

@interface SILUUIDProvider ()

@property (strong, nonatomic, readwrite) CBUUID *otaServiceUUID;
@property (strong, nonatomic, readwrite) CBUUID *otaCharacteristicDataUUID;
@property (strong, nonatomic, readwrite) CBUUID *otaCharacteristicControlUUID;

@end

@implementation SILUUIDProvider

+ (instancetype)sharedProvider {
    static SILUUIDProvider *sharedProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProvider = [[SILUUIDProvider alloc] init];
    });
    return sharedProvider;
}

- (CBUUID *)otaServiceUUID {
    if (_otaServiceUUID == nil) {
        _otaServiceUUID = [CBUUID UUIDWithString:kSILOtaServiceUUIDString];
    }
    return _otaServiceUUID;
}

- (CBUUID *)otaCharacteristicDataUUID {
    if (_otaCharacteristicDataUUID == nil) {
        _otaCharacteristicDataUUID = [CBUUID UUIDWithString:kSILOtaCharacteristicDataUUIDString];
    }
    return _otaCharacteristicDataUUID;
}

- (CBUUID *)otaCharacteristicControlUUID {
    if (_otaCharacteristicControlUUID == nil) {
        _otaCharacteristicControlUUID = [CBUUID UUIDWithString:kSILOtaCharacteristicControlUUIDString];
    }
    return _otaCharacteristicControlUUID;
}

+ (NSString *)predefinedNameForServiceOrCharacteristicUUID:(NSString*)uuid {
    if (!kSILOtaServiceAndCharacteristicNamesForUUIDs) {
        kSILOtaServiceAndCharacteristicNamesForUUIDs = @{
                                                 kSILOtaServiceUUIDString : @"OTA Service",
                                                 kSILOtaCharacteristicDataUUIDString : @"OTA Data",
                                                 kSILOtaCharacteristicControlUUIDString : @"OTA Control",
                                                 kSILOtaCharacteristicFirmwareVersionUUIDString : @"OTA Firmware Version",
                                                 kSILOtaCharacteristicOtaVersionUUIDString : @"OTA Version"
                                                 };
    }
    return kSILOtaServiceAndCharacteristicNamesForUUIDs[[uuid lowercaseString]];
}

@end
