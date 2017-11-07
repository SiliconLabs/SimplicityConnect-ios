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
@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataModel *> *advertisementDataModelsForDevicesTable;
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

- (NSArray *)advertisementDataModelsForDevicesTable {
    if (_advertisementDataModelsForDevicesTable == nil) {
        _advertisementDataModelsForDevicesTable = [self advertisementDataModelsExcept:@[@(AdModelTypeUUID), @(AdModelTypeName), @(AdModelTypeRSSI), @(AdModelTypeServiceUUID)]];
    }
    return _advertisementDataModelsForDevicesTable;
}

- (NSArray *)advertisementDataModelsForInfoView {
    if (_advertisementDataModelsForInfoView == nil) {
        _advertisementDataModelsForInfoView = [self.advertisementDataModels copy];
    }
    return _advertisementDataModelsForInfoView;
}

#pragma mark - Helpers

- (NSArray *)advertisementDataModelsForPeripheral:(SILDiscoveredPeripheral *)device {
    NSMutableArray *mutableAdvModels = [[NSMutableArray alloc] init];

    SILAdvertisementDataModel *uuidModel = [[SILAdvertisementDataModel alloc] initWithValue:device.peripheral.identifier.UUIDString type:AdModelTypeUUID];
    [mutableAdvModels addObject:uuidModel];

    for (CBUUID *serviceUUID in device.advertisedServiceUUIDs) {
        SILAdvertisementDataModel *uuidModel = [[SILAdvertisementDataModel alloc] initWithValue:serviceUUID.UUIDString type:AdModelTypeServiceUUID];
        [mutableAdvModels addObject:uuidModel];
    }

    SILAdvertisementDataModel *rssiModel = [[SILAdvertisementDataModel alloc] initWithValue:[device.RSSIMeasurementTable.lastRSSIMeasurement stringValue] type:AdModelTypeRSSI];
    [mutableAdvModels addObject:rssiModel];

    if (device.advertisedLocalName) {
        SILAdvertisementDataModel *nameModel = [[SILAdvertisementDataModel alloc] initWithValue:device.advertisedLocalName
                                                                                           type:AdModelTypeName];
        [mutableAdvModels addObject:nameModel];
    }

    SILAdvertisementDataModel *connectModel = [[SILAdvertisementDataModel alloc] initWithValue:(device.isConnectable ? @"YES" : @"NO")
                                                                                          type:AdModelTypeConnect];
    [mutableAdvModels addObject:connectModel];

    if (device.txPowerLevel) {
        SILAdvertisementDataModel *powerModel = [[SILAdvertisementDataModel alloc] initWithValue:[device.txPowerLevel stringValue]
                                                                                            type:AdModelTypePower];
        [mutableAdvModels addObject:powerModel];
    }

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
