//
// Created by Glenn Martin on 11/10/15.
// Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILEncodingPseudoFieldRowModel.h"
#import "SILCharacteristicTableModel.h"

@interface SILEncodingPseudoFieldRowModel()

@end

// This is like every-other, except that its created on-the-fly within the Debug device details table for
// Characteristics that have no model so we can show their raw data.
@implementation SILEncodingPseudoFieldRowModel

- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index{
    return 0;
}

- (instancetype)initForCharacteristicModel:(SILCharacteristicTableModel * _Nonnull)model {
    self = [super init];
    if (self) {
        self.parentCharacteristicModel = model;
    }
    return self;
}

- (NSData *)dataForFieldWithError:(NSError * __autoreleasing *)error {
    return [[self.parentCharacteristicModel characteristic] value];
}

- (NSString *)primaryTitle {
    return @"ENCODING";
}

- (NSString *)secondaryTitle {
    return @"";
}

@end
