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
NSString * const kSILBlinkyExampleServiceUUIDString =  @"de8a5aac-a99b-c315-0c80-60d4cbb51224";
NSString * const kSILThroughputTestServiceUUIDString = @"bbb99e70-fff7-46cf-abc7-2d32c71820f2";
NSString * const kSILThroughputInformationServiceUUIDString = @"ba1e0e9f-4d81-bae3-f748-3ad55da38b46";

NSString * const kSILOtaCharacteristicOTADataAttributeUUIDString = @"984227f3-34fc-4045-a5d0-2c581f81a153";
NSString * const kSILOtaCharacteristicOTAControlAttributeUUIDString = @"f7bf3564-fb6d-4e53-88a4-5e37e0326063";
NSString * const kSILOtaCharacteristicAppLoaderVersionUUIDString = @"4f4a2368-8cca-451e-bfff-cf0e2ee23e9f";
NSString * const kSILOtaCharacteristicOtaVersionUUIDString = @"4cc07bcf-0868-4b32-9dad-ba4cc41e5316";
NSString * const kSILOtaCharacteristicGeckoBootloarderVersionUUIDString = @"25f05c0a-e917-46e9-b2a5-aa2be1245afe";
NSString * const kSILOtaCharacteristicApplicationVersionUUIDString = @"0d77cc11-4ac1-49f2-bfa9-cd96ac7a92f8";
NSString * const kSILLEDControl = @"5b026510-4088-c297-46d8-be6c736a087a";
NSString * const kSILReportButton = @"61a885a4-41c3-60d0-9a53-6d652a70d29c";
NSString * const kSILIndications = @"6109b631-a643-4a51-83d2-2059700ad49f";
NSString * const kSILNotifications = @"47b73dd6-dee3-4da1-9be0-f5c539a9a4be";
NSString * const kSILTransmissionON = @"be6b6be1-cd8a-4106-9181-5ffe2bc67718";
NSString * const kSILThroughputResult = @"adf32227-b00f-400c-9eeb-b903a6cc291b";
NSString * const kSILConnectionPHY = @"00a82b93-0feb-2739-72be-abda1f5993d0";
NSString * const kSILConnectionInterval = @"0a32f5a6-0a6c-4954-f413-a698faf2c664";
NSString * const kSILSlaveLatency = @"ff629b92-332b-e7f7-975f-0e535872ddae";
NSString * const kSILSupervisionTimeout = @"67e2c4f2-2f50-914c-a611-adb3727b056d";
NSString * const kSILPDUSize = @"30cc364a-0739-268c-4926-36f112631e0c";
NSString * const kSILMTUSize = @"3816df2f-d974-d915-d26e-78300f25e86e";


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
        kSILBlinkyExampleServiceUUIDString: @"Blinky Example",
        kSILThroughputTestServiceUUIDString: @"Throughput Test Service",
        kSILThroughputInformationServiceUUIDString: @"Throughput Information Service",
    };
}

- (void)preparePredefinedCharacteristicsNames {
    _predefinedCharacteristicsNames = @{
        kSILOtaCharacteristicOTADataAttributeUUIDString : @"OTA Data Attribute",
        kSILOtaCharacteristicOTAControlAttributeUUIDString : @"OTA Control Attribute",
        kSILOtaCharacteristicAppLoaderVersionUUIDString : @"AppLoader version",
        kSILOtaCharacteristicOtaVersionUUIDString : @"OTA version",
        kSILOtaCharacteristicGeckoBootloarderVersionUUIDString : @"Gecko Bootloarder version",
        kSILOtaCharacteristicApplicationVersionUUIDString : @"Application version",
        kSILLEDControl : @"LED Control",
        kSILReportButton : @"Report Button",
        kSILIndications : @"Indications",
        kSILNotifications : @"Notifications",
        kSILTransmissionON : @"Transmission ON",
        kSILThroughputResult : @"Throughput result",
        kSILConnectionPHY : @"Connection PHY",
        kSILConnectionInterval : @"Connection interval",
        kSILSlaveLatency : @"Slave latency",
        kSILSupervisionTimeout : @"Supervision timeout",
        kSILPDUSize : @"PDU size",
        kSILMTUSize : @"MTU size",
    };
}

- (NSString *)predefinedNameForServiceUUID:(NSString*)uuid {
    return self.predefinedServicesNames[[uuid lowercaseString]];
}

-(NSString *)predefinedNameForCharacteristicUUID:(NSString *)uuid {
    return self.predefinedCharacteristicsNames[[uuid lowercaseString]];
}

@end
