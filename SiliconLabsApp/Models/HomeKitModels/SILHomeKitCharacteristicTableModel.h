//
//  SILHomeKitCharacteristicTableModel.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILGenericAttributeTableModel.h"
#import "SILCharacteristicFieldRow.h"
#import "SILFieldRequirementEnforcer.h"

@class HMCharacteristic, CBPeripheral, SILBluetoothCharacteristicModel, SILCharacteristicFieldBuilder;

@interface SILHomeKitCharacteristicTableModel : NSObject <SILGenericAttributeTableModel, SILFieldRequirementEnforcer>

@property (strong, nonatomic) HMCharacteristic *characteristic;
@property (strong, nonatomic) SILBluetoothCharacteristicModel *bluetoothModel;
@property (strong, nonatomic) NSArray *fieldTableRowModels;
@property (strong, nonatomic) NSArray *descriptorModels;
@property (nonatomic, readonly) BOOL canWrite;

@property (strong, nonatomic) NSString *name;

- (instancetype)initWithCharacteristic:(HMCharacteristic *)characteristic;
- (void)updateRead:(HMCharacteristic *)characteristic;
- (void)setIfAllowedFullWriteValue:(NSData *)value;
///@discussion won't write to peripheral if this model cannot write
- (void)writeIfAllowedToPeripheral:(CBPeripheral *)peripheral;
- (void)updateWithField:(id<SILCharacteristicFieldRow>)fieldModel;
- (NSData *)dataToWrite;

- (BOOL)isUnknown;
@end
