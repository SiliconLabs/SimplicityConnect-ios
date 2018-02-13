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
@property (strong, nonatomic) NSMutableArray *discoveredCompatibleDevices;
@property (strong, nonatomic) NSMutableArray *discoveredOtherDevices;
@property (strong, nonatomic) SILDiscoveredPeripheral *connectingPeripheral;
@property (assign, nonatomic) BOOL hasDataChanged;

- (instancetype)initWithAppType:(SILApp *)app;
- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray *)discoveredPeripherals;
- (NSArray *)discoveredDevicesForIndex:(NSInteger)index;
- (NSArray *)availableTabs;
- (NSString *)selectDeviceString;
- (NSString *)appTitleLabelString;
- (NSString *)appDescriptionString;
- (NSAttributedString *)appShowcaseLabelString;


@end
