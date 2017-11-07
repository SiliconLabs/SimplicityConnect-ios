//
//  SILBluetoothBitFieldModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothBitFieldModel.h"

@implementation SILBluetoothBitFieldModel

- (instancetype)initWithBits:(NSArray *)bits {
    self = [super init];
    if (self) {
        self.bits = bits;
    }
    return self;
}

@end
