//
//  SILBrowserConnectionsViewModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserConnectionsViewModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILBrowserConnectionsViewModel ()

@property (strong, nonatomic, readwrite) NSMutableArray<SILDiscoveredPeripheralDisplayDataViewModel *> * allPeripherals;
@property (strong, nonatomic, readwrite) NSMutableArray<SILDisconnectionToastModel*>* toastsToDisplayList;
@property (strong, nonatomic) NSTimer* toastsToDisplayChecker;

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
        self.toastsToDisplayList = [[NSMutableArray alloc] init];
        self.toastsToDisplayChecker = [self setupToastToDisplayChecker];
        [self addObserverForDisconnectPeripheral];
        [self addObserverForDeleteDisconnectedPeripheral];
        [self addObserverForDisconnectAllPeripheral];
        [self addObserverForDisplayToastRequest];
        [self addObserverForFailedToConnectPeripheral];
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

- (void)addObserverForDisplayToastRequest {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayToastIfNeeded) name:SILNotificationDisplayToastRequest object:nil];
}

- (void)addObserverForFailedToConnectPeripheral {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addFailedConnectionToastToDisplay:) name:SILNotificationFailedToConnectPeripheral object:nil];
}

- (NSTimer*)setupToastToDisplayChecker {
    return [NSTimer scheduledTimerWithTimeInterval:1.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.toastsToDisplayList.count > 0) {
            [self displayToastIfNeeded];
            [self.toastsToDisplayChecker invalidate];
        }
    }];
}

- (void)addNewConnectedPeripheral:(CBPeripheral*)peripheral {
    if ([self isUniquePeripheral:peripheral]) {
        SILDiscoveredPeripheral *discoveredPeripheral = [self.centralManager discoveredPeripheralForPeripheral:peripheral];
        SILDiscoveredPeripheralDisplayDataViewModel* connectedPeripheral = [[SILDiscoveredPeripheralDisplayDataViewModel alloc] initWithDiscoveredPeripheralDisplayData:discoveredPeripheral];
        [_allPeripherals addObject:connectedPeripheral];
        _peripherals = [_allPeripherals copy];
        [self postReloadConnectionTableViewNotification];
    }
}
     
- (void)disconnectAllPeripheral {
    for (SILDiscoveredPeripheralDisplayDataViewModel* connectedPeripheral in _allPeripherals) {
        [_centralManager disconnectFromPeripheral:connectedPeripheral.discoveredPeripheral.peripheral];
    }
    [self postReloadConnectionTableViewNotification];
}

- (void)disconnectPeripheral:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* indexNumber = (NSNumber*)userInfo[SILNotificationKeyIndex];
    NSUInteger index = [indexNumber unsignedIntValue];
    
    SILDiscoveredPeripheralDisplayDataViewModel* connectedPeripheral = _peripherals[index];
    [_centralManager disconnectFromPeripheral:connectedPeripheral.discoveredPeripheral.peripheral];
}

- (void)postReloadConnectionTableViewNotification {
    [self notifyObjectChanged];
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadConnectionsTableView object:self userInfo:nil];
}

- (void)deleteDisconnectedPeripheral:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSString* uuid = (NSString*)userInfo[SILNotificationKeyUUID];
    NSString* errorCodeString = (NSString*)userInfo[SILNotificationKeyError];
    int errorCode = [errorCodeString intValue];
    
    for (SILDiscoveredPeripheralDisplayDataViewModel* connectedPeripheral in _peripherals) {
        if ([connectedPeripheral.discoveredPeripheral.peripheral.identifier.UUIDString isEqualToString:uuid]) {
            [self.allPeripherals removeObject:connectedPeripheral];
            self.peripherals = [self.allPeripherals copy];
            if (errorCode != 0) {
                [self.toastsToDisplayList addObject:[[SILDisconnectionToastModel alloc] initWithPeripheralName:connectedPeripheral.discoveredPeripheral.peripheral.name errorCode:errorCode peripheralWasConnected:YES]];
            }
        }
    }
    
    [self postReloadConnectionTableViewNotification];
}

- (BOOL)isUniquePeripheral:(CBPeripheral*)peripheral {
    for (SILDiscoveredPeripheralDisplayDataViewModel* connectedPeripheral in _peripherals) {
        if ([connectedPeripheral.discoveredPeripheral.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)clearViewModelData {
    self.allPeripherals = [[NSMutableArray alloc] init];
    self.peripherals = [[NSArray alloc] init];
}

- (void)displayToastIfNeeded {
    if (self.toastsToDisplayList.count > 0) {
        SILDisconnectionToastModel* toastToShow = [self.toastsToDisplayList objectAtIndex:0];
        NSString* ErrorMessage = [toastToShow getErrorMessageForToast];
        [self.toastsToDisplayList removeObjectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDisplayToastResponse
                                                            object:self
                                                          userInfo: @{
                                                              SILNotificationKeyDescription : ErrorMessage
                                                          }];
    } else {
        self.toastsToDisplayChecker = [self setupToastToDisplayChecker];
    }
}

- (BOOL)isConnectedPeripheral:(CBPeripheral*)peripheral {
    return ![self isUniquePeripheral:peripheral];
}

- (void)addFailedConnectionToastToDisplay:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSString* peripheralName = (NSString*)userInfo[SILNotificationKeyPeripheralName];
    NSString* errorCodeString = (NSString*)userInfo[SILNotificationKeyError];
    int errorCode = [errorCodeString intValue];
    [self.toastsToDisplayList addObject:[[SILDisconnectionToastModel alloc] initWithPeripheralName:peripheralName errorCode:errorCode peripheralWasConnected:NO]];
}

- (BOOL)areConnections {
    return _allPeripherals.count > 0;
}

- (void)disconnectPeripheralWithIdentifier:(NSString *)cellIdentifier {
    NSUInteger index = [self.peripherals indexOfObjectPassingTest:^BOOL(SILDiscoveredPeripheralDisplayDataViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.discoveredPeripheral.identityKey isEqualToString:cellIdentifier];
    }];
    
    if (index != NSNotFound){
        [self.centralManager disconnectFromPeripheral: self.peripherals[index].discoveredPeripheral.peripheral];
    }
}

@end
