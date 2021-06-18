//
//  SILUUIDProvider.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface SILUUIDProvider : NSObject

+ (instancetype)sharedProvider;
- (instancetype)init NS_UNAVAILABLE;
- (NSString *)predefinedNameForServiceUUID:(NSString *)uuid;
- (NSString *)predefinedNameForCharacteristicUUID:(NSString *)uuid;

@end

@interface SILUUIDProvider (OTA)

extern NSString * const kSILOtaServiceUUIDString;
extern NSString * const kSILBlinkyExampleServiceUUIDString;
extern NSString * const kSILThroughputTestServiceUUIDString;
extern NSString * const kSILThroughputInformationServiceUUIDString;

extern NSString * const kSILOtaCharacteristicOTADataAttributeUUIDString;
extern NSString * const kSILOtaCharacteristicOTAControlAttributeUUIDString;
extern NSString * const kSILOtaCharacteristicAppLoaderVersionUUIDString;
extern NSString * const kSILOtaCharacteristicOtaVersionUUIDString;
extern NSString * const kSILLEDControl;
extern NSString * const kSILReportButton;
extern NSString * const kSILIndications;
extern NSString * const kSILNotifications;
extern NSString * const kSILTransmissionON;
extern NSString * const kSILThroughputResult;
extern NSString * const kSILConnectionPHY;
extern NSString * const kSILConnectionInterval;
extern NSString * const kSILSlaveLatency;
extern NSString * const kSILSupervisionTimeout;
extern NSString * const kSILPDUSize;
extern NSString * const kSILMTUSize;


@property (strong, nonatomic, readonly) CBUUID *otaServiceUUID;
@property (strong, nonatomic, readonly) CBUUID *otaCharacteristicOTADataAttributeUUID;
@property (strong, nonatomic, readonly) CBUUID *otaCharacteristicOTAControlAttributeUUID;

@end
