//
//  SILToggleTableRowModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldRow.h"

@class SILBluetoothBitModel, SILBluetoothBitFieldModel, SILBluetoothFieldModel;

@interface SILBitRowModel : NSObject<SILCharacteristicFieldRow>

@property (strong, nonatomic, readonly) SILBluetoothBitModel *bit;
@property (strong, nonatomic, readonly) SILBluetoothFieldModel *fieldModel;
@property (strong, nonatomic) NSNumber *toggleState;

- (instancetype)initWithBit:(SILBluetoothBitModel *)bit fieldModel:(SILBluetoothFieldModel *)fieldModel;

@end
