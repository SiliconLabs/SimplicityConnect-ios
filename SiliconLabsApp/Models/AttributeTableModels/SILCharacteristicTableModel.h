//
//  SILCharacteristicTableModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILGenericAttributeTableModel.h"
#import "SILCharacteristicFieldRow.h"
#import "SILFieldRequirementEnforcer.h"

@class CBCharacteristic, CBPeripheral, SILBluetoothCharacteristicModel, SILCharacteristicFieldBuilder;


@interface SILCharacteristicTableModel : NSObject <SILGenericAttributeTableModel, SILFieldRequirementEnforcer >

@property (strong, nonatomic) CBCharacteristic *characteristic;
@property (strong, nonatomic) SILBluetoothCharacteristicModel *bluetoothModel;
@property (strong, nonatomic) NSArray *fieldTableRowModels;
@property (strong, nonatomic) NSArray *descriptorModels;
@property (nonatomic, readonly) BOOL canWrite;
@property (nonatomic) BOOL isUnknown;

- (instancetype)initWithCharacteristic:(CBCharacteristic *)characteristic;
- (NSString *)name;
- (void)updateRead:(CBCharacteristic *)characteristic;
- (void)setIfAllowedFullWriteValue:(NSData *)value;
///@discussion won't write to peripheral if this model cannot write
- (void)writeIfAllowedToPeripheral:(CBPeripheral *)peripheral;
- (void)updateWithField:(id<SILCharacteristicFieldRow>)fieldModel;
- (NSData *)dataToWrite;

- (BOOL)isUnknown;
@end
