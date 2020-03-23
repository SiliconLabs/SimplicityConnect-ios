//
//  SILBrowserConnectionsViewModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserConnectionsViewModel.h"
#import "SILConnectedPeripheralDataModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILBrowserConnectionsViewModel ()

@property (strong, nonatomic, readwrite) NSMutableArray<SILConnectedPeripheralDataModel*>* allPeripherals;

@end

@implementation SILBrowserConnectionsViewModel

#pragma mark - Initializers

+ (instancetype)sharedInstance {
    static SILBrowserConnectionsViewModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SILBrowserConnectionsViewModel alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allPeripherals = [[NSMutableArray alloc] init];
        self.peripherals = [_allPeripherals copy];
        [self addObserverForDisconnectPeripheral];
        [self addObserverForDeleteDisconnectedPeripheral];
        [self addObserverForDisconnectAllPeripheral];
    }
    return self;
}

- (void)addObserverForDisconnectPeripheral {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectPeripheral:) name:SILNotificationDisconnectPeripheral object:nil];
}

- (void)addObserverForDeleteDisconnectedPeripheral {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDisconnectedPeripheral:) name:SILNotificationDeleteDisconnectedPeripheral object:nil];
}

- (void)addObserverForDisconnectAllPeripheral {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectAllPeripheral) name:SILNotificationDisconnectAllPeripheral object:nil];
}

- (void)addNewConnectedPeripheral:(CBPeripheral*)peripheral {
    if ([self isUniquePeripheral:peripheral]) {
        SILConnectedPeripheralDataModel* connectedPeripheral = [[SILConnectedPeripheralDataModel alloc] initWithPeripheral:peripheral andIsSelected:NO];
        [_allPeripherals addObject:connectedPeripheral];
        _peripherals = [_allPeripherals copy];
        [self updateConnectionsView:[_allPeripherals count] - 1];
        [self postReloadConnectionTableViewNotification];
    }
}
     
- (void)disconnectAllPeripheral {
    for (SILConnectedPeripheralDataModel* connectedPeripheral in _allPeripherals) {
        [_centralManager disconnectFromPeripheral:connectedPeripheral.peripheral];
    }
    
    _allPeripherals = [[NSMutableArray alloc] init];
    _peripherals = [_allPeripherals copy];
    [self postReloadConnectionTableViewNotification];
}

- (void)disconnectPeripheral:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* indexNumber = (NSNumber*)userInfo[SILNotificationKeyIndex];
    NSUInteger index = [indexNumber unsignedIntValue];
    
    SILConnectedPeripheralDataModel* connectedPeripheral = _peripherals[index];
    [_centralManager disconnectFromPeripheral:connectedPeripheral.peripheral];
    [_allPeripherals removeObjectAtIndex:index];
    _peripherals = [_allPeripherals copy];
    [self postReloadConnectionTableViewNotification];
}

- (void)postReloadConnectionTableViewNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadConnectionsTableView object:self userInfo:nil];
}

- (void)updateConnectionsView:(NSInteger)index {
    SILConnectedPeripheralDataModel* currentConnectedPeripheral;
    for (int i = 0; i < [_peripherals count]; i++) {
        if (i != index) {
            _peripherals[i].isSelected = NO;
        } else {
            _peripherals[i].isSelected = YES;
            currentConnectedPeripheral = _peripherals[i];
        }
    }
    [self postReloadConnectionTableViewNotification];
}

- (void)deleteDisconnectedPeripheral:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSString* uuid = (NSString*)userInfo[SILNotificationKeyUUID];
    
    for (SILConnectedPeripheralDataModel* connectedPeripheral in _peripherals) {
        if ([connectedPeripheral.peripheral.identifier.UUIDString isEqualToString:uuid]) {
            [_allPeripherals removeObject:connectedPeripheral];
            _peripherals = [_allPeripherals copy];
        }
    }
    
    [self postReloadConnectionTableViewNotification];
}

- (BOOL)isUniquePeripheral:(CBPeripheral*)peripheral {
    for (SILConnectedPeripheralDataModel* connectedPeripheral in _peripherals) {
        if ([connectedPeripheral.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)connectionsViewOnDetailsScreen:(BOOL)isDetailsScreen {
    if (isDetailsScreen == NO) {
        [self updateConnectionsView:NoDeviceFoundedIndex];
    }
}

@end
