//
//  SILCharacteristicFieldValueResolverContext.m
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 25/11/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILCharacteristicFieldValueResolverContext.h"

NSString * const ERROR_DOMAIN = @"com.silabs.BlueGeckoDemoApp.SILCharacteristicFieldValueResolver";

@implementation SILCharacteristicFieldValueResolverContext

- (instancetype)initWithStringValue:(NSString *)stringValue
                    decimalExponent:(NSInteger)decimalExponent
                           rangeMin:(NSNumber *)rangeMin
                           rangeMax:(NSNumber *)rangeMax
                              error:(NSError * __autoreleasing *)error {
    if (self = [super init]) {
        _originalStringValue = stringValue;
        _stringValue = stringValue;
        _decimalExponent = decimalExponent;
        _rangeMin = rangeMin;
        _rangeMax = rangeMax;
        _error = error;
    }
    return self;
}

- (void)setErrorWithKind:(NSString *)errorKind {
    *(self.error) = [NSError errorWithDomain:ERROR_DOMAIN
                                        code:-1
                                    userInfo:@{
                                        @"errorKind": errorKind,
                                        @"minRange": self.rangeMin,
                                        @"maxRange": self.rangeMax,
                                        @"valueExponent": @(self.decimalExponent),
                                    }];
}

@end
