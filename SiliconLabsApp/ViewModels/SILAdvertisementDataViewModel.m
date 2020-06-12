//
//  SILAdvertisementDataViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILAdvertisementDataViewModel.h"
#import "SILBluetoothModelManager.h"

NSString * const kAdModelTypeAdvertisedServiceUUIDs16Bit = @"List of 16-bit Advertised Service UUIDs";
NSString * const kAdModelTypeAdvertisedServiceUUIDs32Bit = @"List of 32-bit Advertised Service UUIDs";
NSString * const kAdModelTypeAdvertisedServiceUUIDs128Bit = @"List of 128-bit Advertised Service UUIDs";
NSString * const kAdModelTypeSolicitedServiceUUIDs16Bit = @"List of 16-bit Solicited Service UUIDs";
NSString * const kAdModelTypeSolicitedServiceUUIDs128Bit = @"List of 128-bit Solicited Service UUIDs";
NSString * const kAdModelTypeName = @"Complete Local Name";
NSString * const kAdModelTypeTXPowerLevel = @"TX Power Level";
NSString * const kAdModelTypeManufacturerData = @"Manufacturer Specific Data";
NSString * const kAdModelTypeDataServiceData = @"Data Service Data";
NSString * const kAdModelTypeIBeacon = @"iBeacon Data";
NSString * const kAdModelTypeAltBeacon = @"AltBeacon Data";
NSString * const kAdModelTypeEddystoneBeacon = @"Eddystone Data";

@interface SILAdvertisementDataViewModel ()

@property (strong, nonatomic) SILAdvertisementDataModel *advertisementDataModel;
@property (strong, nonatomic, readwrite) NSString *valueString;
@property (strong, nonatomic, readwrite) NSString *typeString;

@end

@implementation SILAdvertisementDataViewModel

#pragma mark - Initializers

- (instancetype)initWithAdvertisementDataModel:(SILAdvertisementDataModel *)dataModel {
    self = [super init];
    if (self) {
        self.advertisementDataModel = dataModel;
    }
    return self;
}

#pragma mark - Properties

- (NSString *)valueString {
    if (_valueString == nil) {
        _valueString = [self valueStringForType:_advertisementDataModel.type];
    }
    return _valueString;
}

- (NSString *)typeString {
    if (_typeString == nil) {
        _typeString = [self typeStringForType:_advertisementDataModel.type];
    }
    return _typeString;
}

#pragma mark - Helpers

- (NSString *)valueStringForType:(AdModelType)type {
    NSString *valueString;
    valueString = _advertisementDataModel.value;
    return valueString;
}

- (NSString *)typeStringForType:(AdModelType)type {
    NSString *typeString;
    switch (type) {
        case AdModelTypeCompleteLocalName:
            typeString = kAdModelTypeName;
            break;
        case AdModelTypeSolicitedServiceUUIDs16Bit:
            typeString = kAdModelTypeSolicitedServiceUUIDs16Bit;
            break;
        case AdModelTypeSolicitedServiceUUIDs128Bit:
            typeString = kAdModelTypeSolicitedServiceUUIDs128Bit;
            break;
        case AdModelTypeTXPowerLevel:
            typeString = kAdModelTypeTXPowerLevel;
            break;
        case AdModelTypeManufacturerData:
            typeString = kAdModelTypeManufacturerData;
            break;
        case AdModelTypeAdvertisedServiceUUIDs16Bit:
            typeString = kAdModelTypeAdvertisedServiceUUIDs16Bit;
            break;
        case AdModelTypeAdvertisedServiceUUIDs32Bit:
            typeString = kAdModelTypeAdvertisedServiceUUIDs32Bit;
            break;
        case AdModelTypeAdvertisedServiceUUIDs128Bit:
            typeString = kAdModelTypeAdvertisedServiceUUIDs128Bit;
            break;
        case AdModelTypeDataServiceData:
            typeString = kAdModelTypeDataServiceData;
            break;
        case AdModelTypeIBeacon:
            typeString = kAdModelTypeIBeacon;
            break;
        case AdModelTypeAltBeacon:
            typeString = kAdModelTypeAltBeacon;
            break;
        case AdModelTypeEddystoneBeacon:
            typeString = kAdModelTypeEddystoneBeacon;
            break;
        default:
            break;
    }
    return typeString;
}

@end

