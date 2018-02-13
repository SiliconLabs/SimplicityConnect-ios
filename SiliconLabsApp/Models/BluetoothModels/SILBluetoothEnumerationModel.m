//
//  SILBluetoothEnumerationModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothEnumerationModel.h"

@implementation SILBluetoothEnumerationModel

- (instancetype)initWithKey:(NSInteger)key value:(NSString *)value requires:(NSString *)requires {
    self = [super init];
    if (self) {
        self.key = key;
        self.value = value;
        self.requires = requires;
    }
    return self;
}

@end
