//
//  SILUUIDProvider.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

extern NSString * const kSILOtaServiceUUIDString;
extern NSString * const kSILOtaCharacteristicDataUUIDString;
extern NSString * const kSILOtaCharacteristicControlUUIDString;

@interface SILUUIDProvider : NSObject

+ (instancetype)sharedProvider;
+ (NSString*)predefinedNameForServiceOrCharacteristicUUID:(NSString*)uuid;

@property (strong, nonatomic, readonly) CBUUID *otaServiceUUID;
@property (strong, nonatomic, readonly) CBUUID *otaCharacteristicDataUUID;
@property (strong, nonatomic, readonly) CBUUID *otaCharacteristicControlUUID;

@end
