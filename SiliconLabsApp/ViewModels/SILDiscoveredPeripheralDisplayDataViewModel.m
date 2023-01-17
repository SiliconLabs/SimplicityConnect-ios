//
//  SILDiscoveredPeripheralDisplayDataViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "SILAdvertisementDataViewModel.h"

@interface SILDiscoveredPeripheralDisplayDataViewModel ()

@property (nonatomic, readwrite) SILDiscoveredPeripheral *discoveredPeripheral;
@property (nonatomic, readwrite) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModels;

@end

@implementation SILDiscoveredPeripheralDisplayDataViewModel

#pragma mark - Initializers

- (instancetype)initWithDiscoveredPeripheralDisplayData:(SILDiscoveredPeripheral *)discoveredPeripheral {
    self = [super self];
    if (self) {
        _discoveredPeripheral = discoveredPeripheral;
    }
    
    return self;
}
#pragma mark - Properties

- (NSArray<SILAdvertisementDataViewModel *> *)advertisementDataViewModels {
    NSArray<SILAdvertisementDataModel *> *dataModels = [self advertisementDataModelsForPeripheral:self.discoveredPeripheral];
    
    NSMutableArray<SILAdvertisementDataViewModel *> *viewModels = [NSMutableArray.alloc init];
    for (int index = 0; index < dataModels.count; index++) {
        SILAdvertisementDataViewModel *viewModel = [SILAdvertisementDataViewModel.alloc initWithAdvertisementDataModel:dataModels[index]];
        [viewModels addObject:viewModel];
    }
    
    return viewModels;
}

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
        if (!isFirst) {
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


@end
