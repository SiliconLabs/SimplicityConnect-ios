//
//  SILBluetoothServiceCharacteristicModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothServiceCharacteristicModel.h"

@implementation SILBluetoothServiceCharacteristicModel

- (instancetype)initWithName:(NSString *)name type:(NSString *)type {
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
    }
    return self;
}

@end
