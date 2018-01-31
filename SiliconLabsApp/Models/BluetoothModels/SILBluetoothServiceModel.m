//
//  SILBluetoothServiceModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothServiceModel.h"

@implementation SILBluetoothServiceModel

- (instancetype)initWithName:(NSString *)name summary:(NSString *)summary uuid:(NSString *)uuidString {
    self = [super init];
    if (self) {
        self.name = name;
        self.summary = summary;
        self.uuidString = uuidString;
    }
    return self;
}

@end
