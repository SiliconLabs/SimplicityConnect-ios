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
@property (nonatomic, readonly) BOOL isUnknown;
@property (nonatomic) Boolean isMappable;

- (instancetype)initWithCharacteristic:(CBCharacteristic *)characteristic;
- (NSString *)name;
- (void)updateRead:(CBCharacteristic *)characteristic;
- (void)setIfAllowedFullWriteValue:(NSData *)value;
- (void)updateWithField:(id<SILCharacteristicFieldRow>)fieldModel;
///@discussion won't write to peripheral if this model cannot write
- (BOOL)writeIfAllowedToPeripheral:(CBPeripheral *)peripheral withWriteType:(CBCharacteristicWriteType)writeType error:(NSError**)error;
- (NSData *)dataToWriteWithError:(NSError * __autoreleasing *)error;
- (void)readCharacteristicIfAllowed;
- (BOOL)clearModel;
- (void)expandFieldIfNeeded;

@end
