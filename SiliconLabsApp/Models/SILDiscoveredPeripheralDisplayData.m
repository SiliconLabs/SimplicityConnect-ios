//
//  SILDiscoveredPeripheralDisplayData.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/22/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILDiscoveredPeripheralDisplayData.h"
#import "SILDiscoveredPeripheral.h"
#import "SILAdvertisementDataModel.h"
#import "SILRSSIMeasurementTable.h"

@interface SILDiscoveredPeripheralDisplayData ()

@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataModel *> *advertisementDataModels;
@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataModel *> *advertisementDataModelsForInfoView;

@end

@implementation SILDiscoveredPeripheralDisplayData

#pragma mark - Initializers

- (instancetype)initWithDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    self = [super self];
    if (self) {
        self.discoveredPeripheral = discoveredPeripheral;
        self.advertisementDataModels = [self advertisementDataModelsForPeripheral:discoveredPeripheral];
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)advertisementDataModelsForInfoView {
    if (_advertisementDataModelsForInfoView == nil) {
        _advertisementDataModelsForInfoView = [self.advertisementDataModels copy];
    }
    return _advertisementDataModelsForInfoView;
}

#pragma mark - Helpers

- (NSArray *)advertisementDataModelsForPeripheral:(SILDiscoveredPeripheral *)device {
    if (device.peripheral != nil) {
        return [self adverisementDataModelsForCBPeripheral:device];
    } else {
        return [self advertisementDataModelsForCLBeacon:device];
    }
    return nil;
}

- (NSArray*)adverisementDataModelsForCBPeripheral:(SILDiscoveredPeripheral*)device {
    SILAdTypeCBPeripheralDecoder* decoder = [[SILAdTypeCBPeripheralDecoder alloc] initWithPeripheral:device];
    return [decoder decode];
}

- (NSArray*)advertisementDataModelsForCLBeacon:(SILDiscoveredPeripheral*)device {
    NSMutableArray *mutableAdvModels = [[NSMutableArray alloc] init];
    NSMutableString* iBeaconDataString = [[NSMutableString alloc] init];
    SILBeacon* beacon = device.beacon;
    BOOL isFirst = YES;
    if (beacon.minor) {
        [iBeaconDataString appendString:@"Minor: "];
        NSString* minorStringValue = [NSString stringWithFormat:@"%hu", beacon.minor];
        [iBeaconDataString appendString:minorStringValue];
        isFirst = NO;
    }
    if (beacon.major) {
        if (isFirst == YES) {
            isFirst = NO;
        } else {
            [iBeaconDataString appendString:@"\n"];
        }
        [iBeaconDataString appendString:@"Major: "];
        NSString* majorStringValue = [NSString stringWithFormat:@"%hu", beacon.major];
        [iBeaconDataString appendString:majorStringValue];
    }
    if (beacon.UUIDString) {
        if (isFirst == YES) {
            isFirst = NO;
        } else {
            [iBeaconDataString appendString:@"\n"];
        }
        [iBeaconDataString appendString:@"UUID: "];
        [iBeaconDataString appendString:beacon.UUIDString];
    }
    
    if (beacon.beacon.proximity && beacon.beacon.accuracy) {
        if (isFirst == YES) {
            isFirst = NO;
        } else {
            [iBeaconDataString appendString:@"\n"];
        }
        [iBeaconDataString appendFormat:@"Distance from iBeacon: "];
        [iBeaconDataString appendFormat:@"%ld +/- %.2f meters", (long)beacon.beacon.proximity, beacon.beacon.accuracy];
    }
    
    SILAdvertisementDataModel* iBeaconModel = [[SILAdvertisementDataModel alloc] initWithValue:iBeaconDataString type:AdModelTypeIBeacon];
    [mutableAdvModels addObject:iBeaconModel];
    
    return mutableAdvModels;
}


- (NSArray *)advertisementDataModelsExcept:(NSArray *)exlcudeTypes {
    NSMutableArray *filteredModels = [[NSMutableArray alloc] init];
    for (SILAdvertisementDataModel *model in self.advertisementDataModels) {
        BOOL addModel = YES;
        for (NSNumber *type in exlcudeTypes) {
            if (type.integerValue == model.type) {
                addModel = NO;
                break;
            }
        }
        if (addModel) {
            [filteredModels addObject:model];
        }
    }
    return [filteredModels copy];
}

@end
