//
//  SILBitFieldFieldModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/29/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldRow.h"

@interface SILBitFieldFieldModel : NSObject <SILCharacteristicFieldRow>

@property (strong, nonatomic, readonly) SILBluetoothFieldModel *fieldModel;
- (instancetype)initBitFieldWithField:(SILBluetoothFieldModel *)fieldModel;
- (NSArray *)bitRowModels;

@end
