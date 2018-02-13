//
//  SILValueFieldTableRowModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldBuilder.h"
#import "SILCharacteristicFieldRow.h"

@class SILBluetoothFieldModel;

@interface SILValueFieldRowModel : NSObject <SILCharacteristicFieldRow>
@property (strong, nonatomic) NSString *primaryValue;
@property (strong, nonatomic, readonly) SILBluetoothFieldModel *fieldModel;
- (instancetype)initWithField:(SILBluetoothFieldModel *)fieldModel;
@end
