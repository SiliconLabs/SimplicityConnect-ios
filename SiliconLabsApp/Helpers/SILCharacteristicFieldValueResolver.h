//
//  SILCharacteristicFieldValueResolver.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/27/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const FieldReadErrorMessage;

@interface SILCharacteristicFieldValueResolver : NSObject

+ (instancetype)sharedResolver;
- (NSString *)readValueString:(NSData *)value forFormat:(NSString *)format;
- (NSData *)dataForValueString:(NSString *)string asFormat:(NSString *)format;
- (NSArray *)binaryArrayFromValue:(NSData *)value forFormat:(NSString *)format;
- (NSData *)subsectionOfData:(NSData *)value fromIndex:(NSInteger)index forFormat:(NSString *)format;
- (NSString *)hexStringForData:(NSData *)value;
- (BOOL)isLegalHexString:(NSString *)hexPairString length:(NSUInteger)length;
- (NSString *)asciiStringForData:(NSData *)value;
- (NSString *)decimalStringForData:(NSData *)value;
- (BOOL)isLegalDecimalString:(NSString *)decimalString;
- (NSData *)dataForHexString:(NSString *)hexString;
- (NSData *)dataForAsciiString:(NSString *)asciiString;
- (NSData *)dataForDecimalString:(NSString *)decimalString;
- (NSUInteger)bitCountForFormat:(NSString *)format;
- (NSUInteger)byteCountForFormat:(NSString *)format;
- (int)exponentOfIntegerBaseForFloat:(Float32)number;

@end
