//
//  SILDeviceSelectionViewModel.h
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILDiscoveredPeripheral.h"
#import "SILApp.h"

@interface SILDeviceSelectionViewModel : NSObject

@property (strong, nonatomic) SILApp *app;
@property (strong, nonatomic) NSArray<SILDiscoveredPeripheral*>* discoveredDevices;
@property (strong, nonatomic) SILDiscoveredPeripheral *connectingPeripheral;
@property (assign, nonatomic) BOOL hasDataChanged;
@property (nonatomic, copy) BOOL (^filter)(SILDiscoveredPeripheral*);

- (instancetype)initWithAppType:(SILApp *)app;
- (instancetype)initWithAppType:(SILApp *)app withFilterByName:(NSString *)name;
- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals;
- (NSString *)selectDeviceString;

@end
