//
//  SILBrowserConnectionsViewModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILCentralManager.h"

@interface SILBrowserConnectionsViewModel : NSObject

@property (strong, nonatomic, readwrite) NSArray<SILDiscoveredPeripheralDisplayDataViewModel *> *peripherals;
@property (strong, nonatomic, readwrite) SILCentralManager* centralManager;
@property (nonatomic) BOOL isActiveScrollingUp;

+ (instancetype)sharedInstance;
- (void)addNewConnectedPeripheral:(CBPeripheral*)peripheral;
- (void)disconnectAllPeripheral;
- (BOOL)isConnectedPeripheral:(CBPeripheral*)peripheral;
- (void)clearViewModelData;
- (BOOL)areConnections;
- (void)disconnectPeripheralWithIdentifier:(NSString *)cellIdentifier;

@end
