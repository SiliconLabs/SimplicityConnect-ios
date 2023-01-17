//
//  SILBrowserConnectionsViewModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBrowserConnectionsViewModel_h
#define SILBrowserConnectionsViewModel_h

#import "SILConnectedPeripheralDataModel.h"
#import "SILCentralManager.h"

@interface SILBrowserConnectionsViewModel : NSObject

@property (strong, nonatomic, readwrite) NSArray<SILConnectedPeripheralDataModel*>* peripherals;
@property (strong, nonatomic, readwrite) SILCentralManager* centralManager;

+ (instancetype)sharedInstance;
- (void)addNewConnectedPeripheral:(CBPeripheral*)peripheral;
- (void)disconnectAllPeripheral;
- (void)updateConnectionsView:(NSInteger)index;
- (void)connectionsViewOnDetailsScreen:(BOOL)isDetailsScreen;
- (BOOL)isConnectedPeripheral:(CBPeripheral*)peripheral;
- (void)clearViewModelData;
- (BOOL)areConnections;
- (void)disconnectPeripheralWithIdentifier:(NSString *)cellIdentifier;

@end

#endif /* SILBrowserConnectionsViewModel_h */
