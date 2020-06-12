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
NSString * const kSILOtaCharacteristicOTADataAttributeUUIDString = @"984227f3-34fc-4045-a5d0-2c581f81a153";
NSString * const kSILOtaCharacteristicOTAControlAttributeUUIDString = @"f7bf3564-fb6d-4e53-88a4-5e37e0326063";
NSString * const kSILOtaCharacteristicAppLoaderVersionUUIDString = @"4f4a2368-8cca-451e-bfff-cf0e2ee23e9f";
NSString * const kSILOtaCharacteristicOtaVersionUUIDString = @"4cc07bcf-0868-4b32-9dad-ba4cc41e5316";
NSString * const kSILOtaCharacteristicGeckoBootloarderVersionUUIDString = @"25f05c0a-e917-46e9-b2a5-aa2be1245afe";
NSString * const kSILOtaCharacteristicApplicationVersionUUIDString = @"0d77cc11-4ac1-49f2-bfa9-cd96ac7a92f8";

- (CBUUID *)otaServiceUUID {
    return [CBUUID UUIDWithString:kSILOtaServiceUUIDString];
}

- (CBUUID *)otaCharacteristicOTADataAttributeUUID {
    return [CBUUID UUIDWithString:kSILOtaCharacteristicOTADataAttributeUUIDString];
}

- (CBUUID *)otaCharacteristicOTAControlAttributeUUID {
    return [CBUUID UUIDWithString:kSILOtaCharacteristicOTAControlAttributeUUIDString];
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
        kSILOtaCharacteristicOTADataAttributeUUIDString : @"OTA Data Attribute",
        kSILOtaCharacteristicOTAControlAttributeUUIDString : @"OTA Control Attribute",
        kSILOtaCharacteristicAppLoaderVersionUUIDString : @"AppLoader version",
        kSILOtaCharacteristicOtaVersionUUIDString : @"OTA version",
        kSILOtaCharacteristicGeckoBootloarderVersionUUIDString : @"Gecko Bootloarder version",
        kSILOtaCharacteristicApplicationVersionUUIDString : @"Application version"
    };
}

- (NSString *)predefinedNameForServiceUUID:(NSString*)uuid {
    return self.predefinedServicesNames[[uuid lowercaseString]];
}

-(NSString *)predefinedNameForCharacteristicUUID:(NSString *)uuid {
    return self.predefinedCharacteristicsNames[[uuid lowercaseString]];
}

@end
