//
//  SILOTAHUDPeripheralViewModel.h
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 4/3/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "CBPeripheral+Services.h"
#import "SILCentralManager.h"

#ifndef SILOTAHUDPeripheralViewModel_h
#define SILOTAHUDPeripheralViewModel_h

@interface SILOTAHUDPeripheralViewModel : NSObject

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager;

- (NSString *)peripheralName;
- (NSString *)peripheralIdentifier;
- (NSString *)peripheralMaximumWriteValueLength;

@end

#endif /* SILOTAHUDPeripheralViewModel_h */
