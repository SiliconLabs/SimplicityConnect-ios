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
        _advertisementDataModelsForDevicesTable = [self advertisementDataModelsExcept:@[@(AdModelTypeUUID), @(AdModelTypeName), @(AdModelTypeServiceUUID)]];
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
    if (device.peripheral != nil) {
        return [self adverisementDataModelsForCBPeripheral:device];
    } else {
        return [self advertisementDataModelsForCLBeacon:device];
    }
    return nil;
}

- (NSArray*)adverisementDataModelsForCBPeripheral:(SILDiscoveredPeripheral*)device {
    NSMutableArray *mutableAdvModels = [[NSMutableArray alloc] init];

    SILAdvertisementDataModel *uuidModel = [[SILAdvertisementDataModel alloc] initWithValue:device.peripheral.identifier.UUIDString type:AdModelTypeUUID];
    [mutableAdvModels addObject:uuidModel];

    for (CBUUID *serviceUUID in device.advertisedServiceUUIDs) {
        SILAdvertisementDataModel *uuidModel = [[SILAdvertisementDataModel alloc] initWithValue:serviceUUID.UUIDString type:AdModelTypeServiceUUID];
        [mutableAdvModels addObject:uuidModel];
    }

    if (device.advertisedLocalName) {
        SILAdvertisementDataModel *nameModel = [[SILAdvertisementDataModel alloc] initWithValue:device.advertisedLocalName
                                                                                           type:AdModelTypeName];
        [mutableAdvModels addObject:nameModel];
    }

    if (device.txPowerLevel) {
        SILAdvertisementDataModel *powerModel = [[SILAdvertisementDataModel alloc] initWithValue:[device.txPowerLevel stringValue]
                                                                                            type:AdModelTypePower];
        [mutableAdvModels addObject:powerModel];
    }
    
    return mutableAdvModels;
}

- (NSArray*)advertisementDataModelsForCLBeacon:(SILDiscoveredPeripheral*)device {
    NSMutableArray *mutableAdvModels = [[NSMutableArray alloc] init];
    SILBeacon* beacon = device.beacon;
    
    SILAdvertisementDataModel *uuidModel = [[SILAdvertisementDataModel alloc] initWithValue:beacon.UUIDString type:AdModelTypeUUID];
    [mutableAdvModels addObject:uuidModel];

    if (beacon.major) {
        NSString* majorStringValue = [NSString stringWithFormat:@"%hu", beacon.major];
        SILAdvertisementDataModel *majorModel = [[SILAdvertisementDataModel alloc] initWithValue:majorStringValue
                                                                                            type:AdModelTypeMajor];
        [mutableAdvModels addObject:majorModel];
    }
    
    if (beacon.minor) {
        NSString* minorStringValue = [NSString stringWithFormat:@"%hu", beacon.minor];
        SILAdvertisementDataModel *minorModel = [[SILAdvertisementDataModel alloc] initWithValue:minorStringValue
                                                                                            type:AdModelTypeMinor];
        [mutableAdvModels addObject:minorModel];
    }
    
    if (beacon.name) {
        SILAdvertisementDataModel *nameModel = [[SILAdvertisementDataModel alloc] initWithValue:device.advertisedLocalName
                                                                                           type:AdModelTypeName];
        [mutableAdvModels addObject:nameModel];
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
