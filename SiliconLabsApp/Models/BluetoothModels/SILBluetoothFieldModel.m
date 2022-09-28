//
//  SILBluetoothFieldModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothFieldModel.h"

@implementation SILBluetoothFieldModel

- (instancetype)initWithName:(NSString *)name unit:(NSString *)unit format:(NSString *)format requires:(NSArray *)requirements {
    self = [super init];
    if (self) {
        self.name = name;
        self.unit = unit;
        self.format = format;
        self.requirements = requirements;
        self.multiplier = 1;
    }
    return self;
}

- (BOOL)isMandatoryField {
    return [self.requirements containsObject:@"Mandatory"];
}

@end
