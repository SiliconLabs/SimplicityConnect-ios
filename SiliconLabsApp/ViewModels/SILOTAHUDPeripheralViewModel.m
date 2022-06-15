//
//  SILOTAHUDPeripheralViewModel.m
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 4/3/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SILOTAHUDPeripheralViewModel.h"
#import "SILOTAFirmwareUpdateManager.h"

NSString * const kUnknownPeripheral = @"Unknown Peripheral";

@interface SILOTAHUDPeripheralViewModel ()
    @property (weak, nonatomic) SILCentralManager *centralManager;
@end

@implementation SILOTAHUDPeripheralViewModel {
    __weak CBPeripheral *_peripheral;
}

#pragma mark - Public

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager {
    self = [super init];
    if (self) {
        _centralManager = centralManager;
        _peripheral = peripheral;
    }
    return self;
}

- (NSString *)peripheralName {
    NSString *name;
    SILDiscoveredPeripheral *discoveredPeripheral = [_centralManager discoveredPeripheralForPeripheral:_peripheral];
    if (discoveredPeripheral) {
        name = discoveredPeripheral.advertisedLocalName;
    }
    if (!name) {
        name = [_peripheral name] ?: kUnknownPeripheral;
    }
    return name;
}

- (NSString *)peripheralIdentifier {
    return [[_peripheral identifier] UUIDString];
}

- (NSString *)peripheralMaximumWriteValueLength {
    NSUInteger maximumWriteValueLength = [SILOTAFirmwareUpdateManager maximumByteAlignedWriteValueLengthForPeripheral:_peripheral forType:CBCharacteristicWriteWithoutResponse];
    return [NSString stringWithFormat:@"%@",  @(maximumWriteValueLength)];
}

@end
