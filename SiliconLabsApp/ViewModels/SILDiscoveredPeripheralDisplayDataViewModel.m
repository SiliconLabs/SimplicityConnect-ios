//
//  SILDiscoveredPeripheralDisplayDataViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "SILDiscoveredPeripheralDisplayData.h"
#import "SILAdvertisementDataViewModel.h"

@interface SILDiscoveredPeripheralDisplayDataViewModel ()

@property (strong, nonatomic, readwrite) SILDiscoveredPeripheralDisplayData *discoveredPeripheralDisplayData;
@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModels;
@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModelsForDevicesTable;
@property (strong, nonatomic, readwrite) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModelsForInfoView;

@end

@implementation SILDiscoveredPeripheralDisplayDataViewModel

#pragma mark - Initializers

- (instancetype)initWithDiscoveredPeripheralDisplayData:(SILDiscoveredPeripheralDisplayData *)discoveredPeripheralDisplayData {
    self = [super self];
    if (self) {
        self.discoveredPeripheralDisplayData = discoveredPeripheralDisplayData;
        self.advertisementDataViewModels = [self advertisementDataViewModelsForDiscoveredPeripheralDisplayData:discoveredPeripheralDisplayData];
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)advertisementDataViewModelsForDevicesTable {
    if (_advertisementDataViewModelsForDevicesTable == nil) {
        _advertisementDataViewModelsForDevicesTable = [self advertisementDataViewModelsForadvertisementDataModels:_discoveredPeripheralDisplayData.advertisementDataModelsForDevicesTable];
    }
    return _advertisementDataViewModelsForDevicesTable;
}

- (NSArray *)advertisementDataViewModelsForInfoView {
    if (_advertisementDataViewModelsForInfoView == nil) {
        _advertisementDataViewModelsForInfoView = [self advertisementDataViewModelsForadvertisementDataModels:_discoveredPeripheralDisplayData.advertisementDataModelsForInfoView];
    }
    return _advertisementDataViewModelsForInfoView;
}

#pragma mark - Helpers

- (NSArray *)advertisementDataViewModelsForDiscoveredPeripheralDisplayData:(SILDiscoveredPeripheralDisplayData *)device {
    return [self advertisementDataViewModelsForadvertisementDataModels:_discoveredPeripheralDisplayData.advertisementDataModels];
}

- (NSArray *)advertisementDataViewModelsForadvertisementDataModels:(NSArray *)advertisementDataModels {
    NSMutableArray *mutableDataViewModels = [NSMutableArray new];
    for (SILAdvertisementDataModel *dataModel in advertisementDataModels) {
        [mutableDataViewModels addObject:[[SILAdvertisementDataViewModel alloc] initWithAdvertisementDataModel:dataModel]];
    }
    return [mutableDataViewModels copy];
}

@end
