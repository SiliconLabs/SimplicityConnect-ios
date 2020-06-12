//
//  SILAdvertisementDataModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/15/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AdModelType) {
    AdModelTypeSolicitedServiceUUIDs16Bit,
    AdModelTypeSolicitedServiceUUIDs128Bit,
    AdModelTypeAdvertisedServiceUUIDs16Bit,
    AdModelTypeAdvertisedServiceUUIDs32Bit,
    AdModelTypeAdvertisedServiceUUIDs128Bit,
    AdModelTypeCompleteLocalName,
    AdModelTypeTXPowerLevel,
    AdModelTypeManufacturerData,
    AdModelTypeDataServiceData,
    AdModelTypeIBeacon,
    AdModelTypeAltBeacon,
    AdModelTypeEddystoneBeacon
};

@interface SILAdvertisementDataModel : NSObject

@property (strong, nonatomic) NSString *value;
@property (nonatomic) AdModelType type;

- (instancetype)initWithValue:(NSString *)value type:(AdModelType)type;

@end
