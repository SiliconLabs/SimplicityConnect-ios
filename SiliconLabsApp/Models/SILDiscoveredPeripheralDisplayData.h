//
//  SILDiscoveredPeripheralDisplayData.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/22/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILDiscoveredPeripheral;
@class SILAdvertisementDataModel;

@interface SILDiscoveredPeripheralDisplayData : NSObject

@property (strong, nonatomic) SILDiscoveredPeripheral *discoveredPeripheral;
@property (strong, nonatomic, readonly) NSArray<SILAdvertisementDataModel *> *advertisementDataModels;
@property (strong, nonatomic, readonly) NSArray<SILAdvertisementDataModel *> *advertisementDataModelsForInfoView;

- (instancetype)initWithDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral;

@end
