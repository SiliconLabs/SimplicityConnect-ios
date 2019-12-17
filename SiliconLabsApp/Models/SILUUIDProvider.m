//
//  SILUUIDProvider.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILUUIDProvider.h"

@implementation SILUUIDProvider (OTA)

NSString * const kSILOtaServiceUUIDString = @"1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0";
NSString * const kSILOtaCharacteristicDataUUIDString = @"984227f3-34fc-4045-a5d0-2c581f81a153";
NSString * const kSILOtaCharacteristicControlUUIDString = @"f7bf3564-fb6d-4e53-88a4-5e37e0326063";
NSString * const kSILOtaCharacteristicFirmwareVersionUUIDString = @"4f4a2368-8cca-451e-bfff-cf0e2ee23e9f";
NSString * const kSILOtaCharacteristicOtaVersionUUIDString = @"4cc07bcf-0868-4b32-9dad-ba4cc41e5316";

- (CBUUID *)otaServiceUUID {
    return [CBUUID UUIDWithString:kSILOtaServiceUUIDString];
}

- (CBUUID *)otaCharacteristicDataUUID {
    return [CBUUID UUIDWithString:kSILOtaCharacteristicDataUUIDString];
}

- (CBUUID *)otaCharacteristicControlUUID {
    return [CBUUID UUIDWithString:kSILOtaCharacteristicControlUUIDString];
}

@end

@interface SILUUIDProvider ()

@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *predefinedServicesNames;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *predefinedCharacteristicsNames;

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

- (instancetype)init {
    if (self = [super init]) {
        [self preparePredefinedServicesNames];
        [self preparePredefinedCharacteristicsNames];
    }
    
    return self;
}

- (void)preparePredefinedServicesNames {
    _predefinedServicesNames = @{
        kSILOtaServiceUUIDString : @"OTA Service",
    };
}

- (void)preparePredefinedCharacteristicsNames {
    _predefinedCharacteristicsNames = @{
        kSILOtaCharacteristicDataUUIDString : @"OTA Data",
        kSILOtaCharacteristicControlUUIDString : @"OTA Control",
        kSILOtaCharacteristicFirmwareVersionUUIDString : @"OTA Firmware Version",
        kSILOtaCharacteristicOtaVersionUUIDString : @"OTA Version",
    };
}

- (NSString *)predefinedNameForServiceUUID:(NSString*)uuid {
    return self.predefinedServicesNames[[uuid lowercaseString]];
}

-(NSString *)predefinedNameForCharacteristicUUID:(NSString *)uuid {
    return self.predefinedCharacteristicsNames[[uuid lowercaseString]];
}

@end
