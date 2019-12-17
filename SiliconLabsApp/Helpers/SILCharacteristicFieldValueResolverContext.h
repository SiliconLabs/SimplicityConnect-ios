//
//  SILCharacteristicFieldValueResolverContext.h
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 25/11/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILCharacteristicFieldValueResolverContext : NSObject

@property (nonatomic, strong, readonly) NSString * originalStringValue;
@property (nonatomic, readonly) NSInteger decimalExponent;
@property (nonatomic, strong, readonly) NSNumber * rangeMin;
@property (nonatomic, strong, readonly) NSNumber * rangeMax;
@property (nonatomic, readonly) NSError * __autoreleasing * error;

@property (nonatomic, strong) NSString * stringValue;
@property (nonatomic, strong) NSNumber * numberValue;

- (instancetype)initWithStringValue:(NSString *)stringValue
                    decimalExponent:(NSInteger)decimalExponent
                           rangeMin:(NSNumber *)rangeMin
                           rangeMax:(NSNumber *)rangeMax
                              error:(NSError * __autoreleasing *)error;

- (void)setErrorWithKind:(NSString *)errorKind;

@end
