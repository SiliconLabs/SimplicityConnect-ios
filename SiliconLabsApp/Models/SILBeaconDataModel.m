//
//  SILBeaconDataModel.m
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILBeaconDataModel.h"

@implementation SILBeaconDataModel

- (instancetype)initWithValue:(NSString *)value type:(BeaconModelType)type {
    self = [super init];
    if (self) {
        self.value = value;
        self.type = type;
    }
    return self;
}

@end
