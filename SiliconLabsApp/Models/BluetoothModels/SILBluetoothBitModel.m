//
//  SILBluetoothBitModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothBitModel.h"

@implementation SILBluetoothBitModel

- (instancetype)initWithName:(NSString *)name index:(NSInteger)index size:(NSInteger)size {
    self = [super init];
    if (self) {
        self.name = name;
        self.index = index;
        self.size = size;
    }
    return self;
}

@end
