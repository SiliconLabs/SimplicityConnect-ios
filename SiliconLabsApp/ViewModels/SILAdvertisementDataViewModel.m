//
//  SILAdvertisementDataViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILAdvertisementDataViewModel.h"
#import "SILBluetoothModelManager.h"

NSString * const kAdModelTypeUUID = @"UUID";
NSString * const kAdModelTypeName = @"LOCAL NAME";
NSString * const kAdModelTypePower = @"POWER LEVEL";
NSString * const kAdModelTypeMajor = @"MAJOR";
NSString * const kAdModelTypeMinor = @"MINOR";

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
    if (type == AdModelTypeServiceUUID) {
        valueString = [NSString stringWithFormat:@"0X%@", _advertisementDataModel.value];
    } else {
        valueString = _advertisementDataModel.value;
    }
    return valueString;
}

- (NSString *)typeStringForType:(AdModelType)type {
    NSString *typeString;
    switch (type) {
        case AdModelTypeName:
            typeString = kAdModelTypeName;
            break;
        case AdModelTypeMajor:
            typeString = kAdModelTypeMajor;
            break;
        case AdModelTypeUUID:
            typeString = kAdModelTypeUUID;
            break;
        case AdModelTypePower:
            typeString = kAdModelTypePower;
            break;
        case AdModelTypeMinor:
            typeString = kAdModelTypeMinor;
            break;
        case AdModelTypeServiceUUID:
            typeString = [self typeStringForServiceUUIDValue:_advertisementDataModel.value];
            break;
        default:
            break;
    }
    return typeString;
}

- (NSString *)typeStringForServiceUUIDValue:(NSString *)value {
    NSString *typeString = [[SILBluetoothModelManager sharedManager] serviceModelForUUIDString:value].name;
    return typeString != nil ? typeString : @"UNKNOWN SERVICE";
}

@end
