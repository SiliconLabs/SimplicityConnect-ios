//
//  SILDiscoveredPeripheralDisplayDataViewModel.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILDiscoveredPeripheralDisplayData;
@class SILAdvertisementDataViewModel;

@interface SILDiscoveredPeripheralDisplayDataViewModel : NSObject

@property (strong, nonatomic, readonly) SILDiscoveredPeripheralDisplayData *discoveredPeripheralDisplayData;
@property (strong, nonatomic, readonly) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModels;
@property (strong, nonatomic, readonly) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModelsForDevicesTable;
@property (strong, nonatomic, readonly) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModelsForInfoView;

- (instancetype)initWithDiscoveredPeripheralDisplayData:(SILDiscoveredPeripheralDisplayData *)discoveredPeripheralDisplayData;

@end
