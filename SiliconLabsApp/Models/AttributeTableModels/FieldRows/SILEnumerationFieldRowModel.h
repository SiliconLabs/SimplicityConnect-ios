//
//  SILEnumerationFieldRow.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldBuilder.h"
#import "SILCharacteristicFieldRow.h"

@class SILBluetoothFieldModel;

@interface SILEnumerationFieldRowModel : NSObject <SILCharacteristicFieldRow>

@property (strong, nonatomic, readonly) NSArray *enumertations;
@property (nonatomic) NSInteger activeValue;
@property (strong, nonatomic, readonly) SILBluetoothFieldModel *fieldModel;
- (instancetype)initWithField:(SILBluetoothFieldModel *)fieldModel;

@end
