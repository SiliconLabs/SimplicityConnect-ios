//
//  SILAdvertisementDataModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/15/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILAdvertisementDataModel.h"

@implementation SILAdvertisementDataModel

- (instancetype)initWithValue:(NSString *)value type:(AdModelType)type {
    self = [super init];
    if (self) {
        self.value = value;
        self.type = type;
    }
    return self;
}

@end
