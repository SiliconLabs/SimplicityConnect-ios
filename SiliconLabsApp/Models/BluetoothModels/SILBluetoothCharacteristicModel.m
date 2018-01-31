//
//  SILBluetoothCharacteristicModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothCharacteristicModel.h"

@implementation SILBluetoothCharacteristicModel

- (instancetype)initWithName:(NSString *)name summary:(NSString *)summary type:(NSString *)type uuid:(NSString *)uuid {
    self = [super init];
    if (self) {
        self.name = name;
        self.summary = summary;
        self.type = type;
        self.uuidString = uuid;
    }
    return self;
}

@end
