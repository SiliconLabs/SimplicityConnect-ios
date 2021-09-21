//
//  SILDiscoveredPeripheralDisplayDataViewModel.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILAdvertisementDataViewModel;

@interface SILDiscoveredPeripheralDisplayDataViewModel : NSObject

@property (nonatomic, readonly) SILDiscoveredPeripheral *discoveredPeripheral;
@property (nonatomic, readonly) NSArray<SILAdvertisementDataViewModel *> *advertisementDataViewModels;

- (instancetype)initWithDiscoveredPeripheralDisplayData:(SILDiscoveredPeripheral *)discoveredPeripheral;

@end
