//
//  SILCharacteristicFieldValueResolver.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/27/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const FieldReadErrorMessage;

@class SILBluetoothFieldModel;

@interface SILCharacteristicFieldValueResolver : NSObject

+ (instancetype)sharedResolver;
- (NSString *)readValueString:(NSData *)value withFieldModel:(SILBluetoothFieldModel *)fieldModel;
- (NSData *)dataForValueString:(NSString *)string withFieldModel:(SILBluetoothFieldModel *)fieldModel error:(NSError *__autoreleasing *)error;
- (NSArray *)binaryArrayFromValue:(NSData *)value forFormat:(NSString *)format;
- (NSData *)subsectionOfData:(NSData *)value fromIndex:(NSInteger)index forFieldModel:(SILBluetoothFieldModel *)field;
- (NSString *)hexStringForData:(NSData *)value decimalExponent:(NSInteger)decimalExponent;
- (BOOL)isLegalHexString:(NSString *)hexPairString length:(NSUInteger)length;
- (NSString *)asciiStringForData:(NSData *)value;
- (NSString *)decimalStringForData:(NSData *)value;
- (BOOL)isLegalDecimalString:(NSString *)decimalString;
- (NSData *)dataForHexString:(NSString *)hexString decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error;
- (NSData *)dataForAsciiString:(NSString *)asciiString;
- (NSData *)dataForDecimalString:(NSString *)decimalString;
- (NSUInteger)bitCountForFormat:(NSString *)format;
- (NSUInteger)byteCountForFormat:(NSString *)format;

@end
