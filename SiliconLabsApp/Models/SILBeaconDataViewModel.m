//
//  SILBeaconDataViewModel.m
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILBeaconDataViewModel.h"
#import "SILBeaconDataModel.h"

//NSString * const kAdModelTypeUUID = @"UUID";

@interface SILBeaconDataViewModel ()

@property (strong, nonatomic) SILBeaconDataModel *beaconDataModel;
@property (strong, nonatomic, readwrite) NSString *valueString;
@property (strong, nonatomic, readwrite) NSString *typeString;

@end

@implementation SILBeaconDataViewModel

#pragma mark - Initializers

- (instancetype)initWithBeaconDataModel:(SILBeaconDataModel *)dataModel {
    self = [super init];
    if (self) {
        self.beaconDataModel = dataModel;
    }
    return self;
}

#pragma mark - Properties

- (NSString *)valueString {
    if (_valueString == nil) {
        _valueString = [self valueStringForType:self.beaconDataModel.type];
    }
    return _valueString;
}

- (NSString *)typeString {
    if (_typeString == nil) {
        _typeString = [self typeStringForType:self.beaconDataModel.type];
    }
    return _typeString;
}

#pragma mark - Helpers

- (NSString *)valueStringForType:(BeaconModelType)type {
    return self.beaconDataModel.value;
}

- (NSString *)typeStringForType:(BeaconModelType)type {
    NSString *typeString;
    switch (type) {
        case BeaconModelTypeURL:
            typeString = @"URL";
            break;
        case BeaconModelTypeUUID:
            typeString = @"UUID";
            break;
        case BeaconModelTypeInstance:
            typeString = @"Instance";
            break;
        case BeaconModelTypeVersion:
            typeString = @"Version";
            break;
        case BeaconModelTypeVoltage:
            typeString = @"Voltage";
            break;
        case BeaconModelTypeTemperature:
            typeString = @"Temperature";
            break;
        case BeaconModelTypeOnTime:
            typeString = @"On time";
            break;
        case BeaconModelTypeAdvertisementCount:
            typeString = @"Advertisement count";
            break;
    }
    return typeString;
}

@end
