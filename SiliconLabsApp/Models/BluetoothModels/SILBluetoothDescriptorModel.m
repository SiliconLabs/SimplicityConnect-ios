//
//  SILBluetoothDescriptorModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothDescriptorModel.h"

@implementation SILBluetoothDescriptorModel

- (instancetype)initWithName:(NSString *)name type:(NSString *)type uuid:(NSString *)uuidString {
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
        self.uuidString = uuidString;
    }
    return self;
}

@end
