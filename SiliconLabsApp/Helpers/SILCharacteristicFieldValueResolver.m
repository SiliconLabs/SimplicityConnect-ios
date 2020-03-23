//
//  SILCharacteristicFieldValueResolver.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/27/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILCharacteristicFieldValueResolver.h"
#import "SILBluetoothFieldModel.h"
#import <Crashlytics/Crashlytics.h>
#import "SILCharacteristicFieldValueResolverContext.h"

NSString * const ERROR_KIND_PARSE = @"Parse";
NSString * const ERROR_KIND_RANGE = @"Range";

NSString * const REGEX_PATTERN_DECIMAL_EXPONENT_EQUALS_0 = @"^[+-]?\\d+$";
NSString * const REGEX_PATTERN_FORMAT_DECIMAL_EXPONENT_GRATER_THAN_0 = @"^[+-]?\\d+0{%ld,}$";
NSString * const REGEX_PATTERN_FORMAT_DECIMAL_EXPONENT_LESS_THAN_0 = @"^[+-]?\\d+(\\.\\d{0,%ld})?$";
NSString * const REGEX_PATTERN_FLOAT = @"^[+-]?\\d+(\\.\\d{0,%ld})?$";
NSString * const NUMBER_PARSING_LOCALE = @"en_US";

typedef NS_ENUM(NSInteger, AppMode) {
    AppMode32Bit,
    AppMode64Bit
};

NSString * const kBooleanFormat = @"boolean";
NSString * const k2BitFormat = @"2bit";
NSString * const kNibbleFormat = @"nibble";
NSString * const k8BitFormat = @"8bit";
NSString * const k16BitFormat = @"16bit";
NSString * const k24BitFormat = @"24bit";
NSString * const k32BitFormat = @"32bit";
NSString * const kU8Format = @"uint8";
NSString * const kU16Format = @"uint16";
NSString * const kU24Format = @"uint24";
NSString * const kU32Format = @"uint32";
NSString * const kU40Format = @"uint40";
NSString * const kU48Format = @"uint48";
NSString * const kU64Format = @"uint64";
NSString * const kU128Format = @"uint128";
NSString * const kS8Format = @"sint8";
NSString * const kS12Format = @"sint12";
NSString * const kS16Format = @"sint16";
NSString * const kS24Format = @"sint24";
NSString * const kS32Format = @"sint32";
NSString * const kS48Format = @"sint48";
NSString * const kS64Format = @"sint64";
NSString * const kS128Format = @"sint128";
NSString * const kF32Format = @"float32";
NSString * const kF64Format = @"float64";
NSString * const kSFloatFormat = @"SFLOAT";
NSString * const kFloatFormat = @"FLOAT";
NSString * const kDU16Format = @"dunit16";
NSString * const kU8StringFormat = @"utf8s";
NSString * const kU16StringFormat = @"utf16s";
NSString * const kRegCertFormat = @"reg-cert-data-list";
NSString * const kVariableFormat = @"variable";

NSString * const kHexDeilimiter = @":";
NSString * const kDecimalDelimiter = @" ";

NSString * const FieldReadErrorMessage = @"Field value not present or unreadable";

int const kSFloatPostiviveInfinity = 0x07FE;
int const kSFloatNan = 0x07FF;
int const kSFloatNegativeInfinity = 0x0802;
int const kFirstSFloatReservedValue = kSFloatPostiviveInfinity;
float const kReservedSFloatValues[5] = {kSFloatPostiviveInfinity, kSFloatNan, kSFloatNan, kSFloatNan, kSFloatNegativeInfinity};

#pragma mark - SILCharacteristicFieldValueResolver

@implementation SILCharacteristicFieldValueResolver

#pragma mark Init

+ (instancetype)sharedResolver {
    static SILCharacteristicFieldValueResolver *sharedResolver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedResolver = [[SILCharacteristicFieldValueResolver alloc] init];
    });
    return sharedResolver;
}

- (NSUInteger)bitCountForFormat:(NSString *)format {
    return [[self formatLengths][format] integerValue];
}

- (NSUInteger)byteCountForFormat:(NSString *)format {
    NSInteger bitCount = [self bitCountForFormat:format];
    NSUInteger byteCount;
    if (bitCount == 0) {
        byteCount = 0; //actually is length of value
    } else if (bitCount <= 8) {
        byteCount = 1;
    } else if (bitCount % 8 != 0) {
        int leftover = bitCount % 8;
        byteCount = (bitCount + (8 - leftover)) / 8;
    } else {
        byteCount = bitCount / 8;
    }
    return byteCount;
}

- (NSUInteger)byteCountForFormat:(NSString *)format withValue:(NSData *)value {
    NSUInteger byteCount = [self byteCountForFormat:format];
    if (byteCount == 0) {
        byteCount = value.length;
    }
    return byteCount;
}

#pragma mark - Data Helpers

- (NSData *)subsectionOfData:(NSData *)value fromIndex:(NSInteger)index forFormat:(NSString *)format {
    NSInteger byteCount = [[SILCharacteristicFieldValueResolver sharedResolver] byteCountForFormat:format withValue:value];
    NSInteger readLength = byteCount + index < value.length ? byteCount: value.length - index;
    NSRange range = {index, readLength};
    NSData *subsectionValue = [value subdataWithRange:range];
    return subsectionValue;
}

#pragma mark - Read

- (NSString *)readValueString:(NSData *)value withFieldModel:(SILBluetoothFieldModel *)fieldModel {
    [CrashlyticsKit setObjectValue:value forKey:@"field_value"];
    if (value.length == 0) {
        return FieldReadErrorMessage;
    }
    
    NSValue * const formatSelector = [self formatSelectors][fieldModel.format];
    NSString * resultValue = nil;
    
    if (formatSelector) {
        resultValue = [self invokeFormatSelector:formatSelector
                                       withValue:value
                                 decimalExponent:fieldModel.decimalExponent];
    } else {
        resultValue = [self utf8StringForValue:value decimalExponent:0];
    }
    
    return resultValue;
}

- (NSString *)invokeFormatSelector:(NSValue *)formatSelector
                         withValue:(NSData *)value
                   decimalExponent:(NSInteger)decimalExponent {
    const SEL selector = formatSelector.pointerValue;
    void *result;
    NSInvocation * const invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&value atIndex:2];
    [invocation setArgument:&decimalExponent atIndex:3];
    [invocation invoke];
    [invocation getReturnValue:&result];
    
    return (__bridge NSString *)result;
}

- (NSNumber *)applyDecimalExponent:(NSInteger)decimalExponent toNumber:(NSNumber *)number {
    NSDecimalNumber * const decimalNumber = [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
    
    return [decimalNumber decimalNumberByMultiplyingByPowerOf10:decimalExponent];
}

#pragma mark - Write

- (NSData *)dataForValueString:(NSString *)string withFieldModel:(SILBluetoothFieldModel *)fieldModel error:(NSError *__autoreleasing *)error {
    NSValue * const dataSelector = [self dataSelectors][fieldModel.format];
    
    if (dataSelector) {
        return [self invokeDataSelector:dataSelector
                        withValueString:string
                        decimalExponent:fieldModel.decimalExponent
                                  error:error];
    } else {
        return [self dataForAsciiString:string];
    }
}

- (NSData *)invokeDataSelector:(NSValue *)dataSelector
               withValueString:(NSString *)string
               decimalExponent:(NSInteger)decimalExponent
                         error:(NSError *__autoreleasing *)error {
    const SEL selector = dataSelector.pointerValue;
    void *result;
    NSInvocation * const invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&string atIndex:2];
    [invocation setArgument:&decimalExponent atIndex:3];
    [invocation setArgument:&error atIndex:4];
    [invocation invoke];
    [invocation getReturnValue:&result];
    
    return (__bridge NSData *)result;
}

- (void)parseStringAsIntegerInContext:(SILCharacteristicFieldValueResolverContext *)context {
    context.stringValue = [self sanitizeStringNumber:context.stringValue];
    
    [self validateStringAsInteger:context];
    
    if (*(context.error)) { return; }
    
    NSLocale * const locale = [NSLocale localeWithLocaleIdentifier:NUMBER_PARSING_LOCALE];
    NSDecimalNumber * const decimalNumber = [NSDecimalNumber decimalNumberWithString:context.stringValue locale:locale];
    
    context.numberValue = [decimalNumber decimalNumberByMultiplyingByPowerOf10:-context.decimalExponent];
}

- (void)parseStringAsFloatInContext:(SILCharacteristicFieldValueResolverContext *)context {
    context.stringValue = [self sanitizeStringNumber:context.stringValue];
    
    [self validateString:context withPattern:REGEX_PATTERN_FLOAT];
    
    if (*(context.error)) { return; }
    
    NSLocale * const locale = [NSLocale localeWithLocaleIdentifier:NUMBER_PARSING_LOCALE];
    
    context.numberValue = [NSDecimalNumber decimalNumberWithString:context.stringValue locale:locale];
}

- (NSString *)sanitizeStringNumber:(NSString *)value {
    NSString * result = value;
    
    result = [result stringByReplacingOccurrencesOfString:@"," withString:@"."];
    result = [result stringByReplacingOccurrencesOfString:@"\\s" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [result length])];
    
    return result;
}

- (void)validateStringAsInteger:(SILCharacteristicFieldValueResolverContext *)context {
    const NSInteger decimalExponent = context.decimalExponent;
    NSString * pattern;
    
    if (decimalExponent == 0) {
        pattern = REGEX_PATTERN_DECIMAL_EXPONENT_EQUALS_0;
    } else if (decimalExponent > 0) {
        pattern = [NSString stringWithFormat:REGEX_PATTERN_FORMAT_DECIMAL_EXPONENT_GRATER_THAN_0, (long)decimalExponent];
    } else if (decimalExponent < 0) {
        pattern = [NSString stringWithFormat:REGEX_PATTERN_FORMAT_DECIMAL_EXPONENT_LESS_THAN_0, (long)-decimalExponent];
    }
    
    [self validateString:context withPattern:pattern];
}

- (void)validateString:(SILCharacteristicFieldValueResolverContext *)context withPattern:(NSString *)pattern {
    NSRegularExpression * const regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    const NSRange searchedRange = NSMakeRange(0, [context.stringValue length]);
    const NSUInteger numberOfMatches = [regex numberOfMatchesInString:context.stringValue options:0 range:searchedRange];
    const BOOL isValid = numberOfMatches == 1;
    
    if (!isValid) {
        [context setErrorWithKind:ERROR_KIND_PARSE];
    }
}

- (BOOL)validateNumberInContext:(SILCharacteristicFieldValueResolverContext *)context {
    if (*(context.error)) { return NO; }
    
    NSNumber * const number = context.numberValue;
    NSNumber * const min = context.rangeMin;
    NSNumber * const max = context.rangeMax;
    const BOOL isRangeDefined = min != nil && max != nil;
    const BOOL isNumberInRange = isRangeDefined && [min doubleValue] <= [number doubleValue] && [number doubleValue] <= [max doubleValue];
    
    if (!isNumberInRange) {
        [context setErrorWithKind:ERROR_KIND_RANGE];
    }
    
    return isNumberInRange;
}

#pragma mark - Binary Helpers

- (NSArray *)binaryArrayFromValue:(NSData *)value forFormat:(NSString *)format {
    NSMutableArray *binaryArray = [NSMutableArray new];
    NSUInteger bitCount = [[self formatLengths][format] unsignedIntegerValue];
    NSUInteger byteSize = [self byteCountForFormat:format withValue:value];
    
    uint8_t *byteBlock = malloc(sizeof(uint8_t) * byteSize);
    [value getBytes:byteBlock length:byteSize];
    
    for (NSInteger bit = 0; bit < bitCount; bit++) {
        int bitValue = (*byteBlock >> bit) & 1;
        [binaryArray addObject:@(bitValue)];
    }
    
    free(byteBlock);
    return binaryArray;
}

- (NSString *)formattedBinaryStringFromValue:(NSData *)value forFormat:(NSString *)format {
    NSArray *binaryArray = [self binaryArrayFromValue:value forFormat:format];
    NSMutableString *binaryString  = [[NSMutableString alloc] initWithString:@""];
    int byteIndex = 0;
    for (NSNumber *bit in binaryArray) {
        if (byteIndex < 8) {
            [binaryString appendString:[bit stringValue]];
            byteIndex++;
        } else {
            [binaryString appendString:@" "];
            byteIndex = 0;
        }
    }
    return  [binaryString copy];
}

#pragma mark - Array values

- (NSArray *)booleanArrayForValue:(NSData *)value {
    return [self binaryArrayFromValue:value forFormat:kBooleanFormat];
}

- (NSArray *)twoBitArrayForValue:(NSData *)value {
    return [self binaryArrayFromValue:value forFormat:k2BitFormat];
}

- (NSArray *)nibbleArrayForValue:(NSData *)value {
    return [self binaryArrayFromValue:value forFormat:kNibbleFormat];
}

#pragma mark - Uint Read

- (NSString *)uint8StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint8_t result = *(uint8_t *)[value bytes];
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint16StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint16_t *uint16Bytes = (uint16_t *)[value bytes];
    uint16_t result = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint24StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint32_t *uint32Bytes = (uint32_t *)[value bytes];
    uint32_t full = (uint32_t)CFSwapInt32LittleToHost(*uint32Bytes);
    uint32_t result = full << 8 >> 8; //clean top bits
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint32StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint32_t *uint32Bytes = (uint32_t *)[value bytes];
    uint32_t result = (uint32_t)CFSwapInt32LittleToHost(*uint32Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint40StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t full = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    uint64_t result = full << 24 >> 24; //clean top bits
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint48StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t full = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    uint64_t result = full << 16 >> 16; //clean top bits
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint64StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t result = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)uint128StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    return [self hexStringForData:value decimalExponent:decimalExponent];
}

#pragma mark - Uint Write

- (NSData *)uint8DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@UINT8_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint8_t casted = (uint8_t)[number unsignedIntValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)uint16DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@UINT16_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint16_t casted = (uint16_t)[number unsignedIntValue];
    const uint16_t result = (uint16_t)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)uint24DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@(UINT32_MAX >> 8)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint32_t casted = (uint32_t)[number unsignedIntValue];
    uint32_t result = (uint32_t)CFSwapInt32HostToLittle(casted);
    result = result << 8 >> 8;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 3)];
}

- (NSData *)uint32DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@UINT32_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint32_t casted = (uint32_t)[number unsignedIntValue];
    const uint32_t result = (uint32_t)CFSwapInt32HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)uint40DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@(UINT64_MAX >> 24)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint64_t casted = [self unsignedLong64BitNumberForNumber:number appMode:[self currentAppMode]];
    uint64_t result = (uint64_t)CFSwapInt64HostToLittle(casted);
    result = result << 24 >> 24;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 5)];
}

- (NSData *)uint48DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@(UINT64_MAX >> 16)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint64_t casted = [self unsignedLong64BitNumberForNumber:number appMode:[self currentAppMode]];
    uint64_t result = (uint64_t)CFSwapInt64HostToLittle(casted);
    result = result << 16 >> 16;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 8)];
}

- (NSData *)uint64DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@0
                                                                   rangeMax:@UINT64_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const uint64_t host = [self unsignedLong64BitNumberForNumber:number appMode:[self currentAppMode]];
    const uint64_t little = (uint64_t)CFSwapInt64HostToLittle(host);
    return [NSData dataWithBytes:&little length:sizeof(uint64_t)];
}

- (NSData *)uint128DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    return [self dataForHexString:string decimalExponent:decimalExponent error:error];
}

#pragma mark - Sint Read

- (SInt64)sintCasterForSint:(SInt64)result originalSize:(int)originalSize castSize:(int)castSize {
    int sign = (result >> (originalSize - 1)) & 1;
    uint64_t mask = sign ? (UINT64_MAX << originalSize) : 0;
    result = result | mask;
    return result;
}

- (NSString *)sint8StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt8 result = *(SInt8 *)[value bytes];
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint12StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt16 *sint16Bytes = (SInt16 *)[value bytes];
    SInt16 result = (SInt16)CFSwapInt16LittleToHost(*sint16Bytes);
    result = result >> 4;
    result = (SInt16)[self sintCasterForSint:result originalSize:12 castSize:16];
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint16StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt16 *sint16Bytes = (SInt16 *)[value bytes];
    SInt16 result = (SInt16)CFSwapInt16LittleToHost(*sint16Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint24StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt32 *sint32Bytes = (SInt32 *)[value bytes];
    SInt32 result = (SInt32)CFSwapInt32LittleToHost(*sint32Bytes);
    result = result << 8 >> 8; //clean up top bits from cast
    result = (SInt32)[self sintCasterForSint:result originalSize:24 castSize:32];
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint32StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt32 *sint32Bytes = (SInt32 *)[value bytes];
    SInt32 result = (SInt32)CFSwapInt32LittleToHost(*sint32Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint48StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt64 *sint64Bytes = (SInt64 *)[value bytes];
    SInt64 result = (SInt64)CFSwapInt64LittleToHost(*sint64Bytes);
    result = result << 16 >> 16; //clean up top bits from cast
    result = (SInt64)[self sintCasterForSint:result originalSize:48 castSize:64];
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

- (NSString *)sint64StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    SInt64 *sint64Bytes = (SInt64 *)[value bytes];
    SInt64 result = (SInt64)CFSwapInt64LittleToHost(*sint64Bytes);
    return [[self applyDecimalExponent:decimalExponent toNumber:@(result)] stringValue];
}

//just return the string of the binary
- (NSString *)sint128StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    return [self hexStringForData:value decimalExponent:decimalExponent];
}

#pragma mark - Sint Write

- (NSData *)sint8DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@INT8_MIN
                                                                   rangeMax:@INT8_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    SInt8 casted = (SInt8)[number intValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)sint12DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@(INT16_MIN >> 4)
                                                                   rangeMax:@(INT16_MAX >> 4)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt16 casted = (SInt16)[number intValue];
    SInt16 result = (SInt16)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(casted)];
}

- (NSData *)sint16DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@INT16_MIN
                                                                   rangeMax:@INT16_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt16 casted = (SInt16)[number intValue];
    const SInt16 result = (SInt16)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(casted)];
}

- (NSData *)sint24DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@(INT32_MIN >> 8)
                                                                   rangeMax:@(INT32_MAX >> 8)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt32 casted = (SInt32)[number intValue];
    SInt32 result = (SInt32)CFSwapInt32HostToLittle(casted);
    result = result << 8 >> 8;
    return [NSData dataWithBytes:&result length:(sizeof(SInt8) * 3)];
}

- (NSData *)sint32DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@INT32_MIN
                                                                   rangeMax:@INT32_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt32 casted = (SInt32)[number intValue];
    const SInt32 result = (SInt32)CFSwapInt32HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint48DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@(INT64_MIN >> 16)
                                                                   rangeMax:@(INT64_MAX >> 16)
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt64 casted = [self long64BitNumberForNumber:number appMode:[self currentAppMode]];
    SInt64 result = (SInt64)CFSwapInt64HostToLittle(casted);
    result = result << 16 >> 16;
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint64DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:@INT64_MIN
                                                                   rangeMax:@INT64_MAX
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const SInt64 casted = [self long64BitNumberForNumber:number appMode:[self currentAppMode]];
    const SInt64 result = (SInt64)CFSwapInt64HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint128DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    return [self dataForHexString:string decimalExponent:decimalExponent error:error];
}

#pragma mark - Float Read

- (NSString *)float32StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    Float32 *float32Bytes = (Float32 *)[value bytes];
    Float32 result = (Float32)CFSwapInt32LittleToHost(*float32Bytes);
    return [@(result) stringValue];
}

- (NSString *)float64StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    Float64 *float64Bytes = (Float64 *)[value bytes];
    Float64 result = (Float64)CFSwapInt64LittleToHost(*float64Bytes);
    return [@(result) stringValue];
}

- (NSString *)floatStringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    int32_t valueBlock;
    [value getBytes:&valueBlock length:sizeof(int32_t)];
    int32_t tempData = (int32_t)CFSwapInt32LittleToHost(*(uint32_t*)&valueBlock);
    int8_t exponenet = (int8_t)(tempData >> 24);
    
    tempData = tempData & 0x00FFFFFF;
    
    if (tempData & 0x00800000) {
        tempData ^= 0x00FFFFFF;
        tempData += 1;
        tempData *= -1;
    }
    
    int32_t mantissa = tempData;
    float result = (float)(mantissa*pow(10, exponenet));
    return [@(result) stringValue];
}

#pragma mark - Float Write

- (NSData *)float32DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:nil
                                                                   rangeMax:nil
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    const Float32 casted = (Float32)[number floatValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)float64DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:nil
                                                                   rangeMax:nil
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    Float64 casted = (Float64)[number floatValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)floatDataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:nil
                                                                   rangeMax:nil
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    Float32 castedFloat = (Float32)[number floatValue];
    int32_t exponent = [self exponentOfIntegerBaseForFloat:castedFloat];
    double magnitude = pow(10.0f, exponent);
    int32_t mantissa = castedFloat / magnitude;
    
    if (mantissa < 0) {
        mantissa += (0xFFFFFF + 1);
    }
    
    if (exponent < 0) {
        exponent += (0xFF + 1);
    }
    
    int32_t floatBuffer = 0;
    floatBuffer = (floatBuffer | exponent) << 24;
    floatBuffer = (floatBuffer | mantissa);
    NSMutableData *floatData = [[NSMutableData alloc] init];
    [floatData appendBytes:&floatBuffer length:sizeof(floatBuffer)];
    return floatData;
}

#pragma mark - SFloat Read

//Used http://www.askstop.net/questions/888055/how-to-convert-ieee-11073-16-bit-sfloat-to-simple-float-in-java as reference
- (NSString *)sfloatStringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    uint16_t intData;
    [value getBytes:&intData length:sizeof(uint16_t)];
    
    int32_t mantissa = intData & 0x0FFF;
    int32_t exponent = intData >> 12;
    
    if (exponent >= 0x8) {
        exponent = -((0xF + 1) - exponent);
    }
    
    float output= 0;
    
    if (mantissa >= kFirstSFloatReservedValue && mantissa <= kSFloatNegativeInfinity) {
        output = kReservedSFloatValues[mantissa -kFirstSFloatReservedValue];
    } else {
        if (mantissa >= 0x800) {
            mantissa = -((0xFFF + 1) - mantissa);
        }
        double magnitude = pow(10.0f, exponent);
        output = (float) (mantissa * magnitude);
    }
    
    return [@(output) stringValue];
}

#pragma mark - SFloat Write

- (NSData *)sfloatDataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolverContext * const context =
    [[SILCharacteristicFieldValueResolverContext alloc] initWithStringValue:string
                                                            decimalExponent:decimalExponent
                                                                   rangeMin:nil
                                                                   rangeMax:nil
                                                                      error:error];
    [self parseStringAsIntegerInContext:context];
    
    if (![self validateNumberInContext:context]) { return nil; }
    
    NSNumber * const number = context.numberValue;
    Float32 castedFloat = (Float32)[number floatValue];
    int32_t exponent = [self exponentOfIntegerBaseForFloat:castedFloat];
    double magnitude = pow(10.0f, exponent);
    int32_t mantissa = castedFloat / magnitude;
    
    if (mantissa < 0) {
        mantissa += (0xFFF + 1);
    }
    
    if (exponent < 0) {
        exponent += (0xF + 1);
    }
    
    SInt16 sfloatBuffer = 0;
    sfloatBuffer = (sfloatBuffer | exponent) << 12;
    sfloatBuffer = (sfloatBuffer | mantissa);
    NSMutableData *sfloatData = [[NSMutableData alloc] init];
    [sfloatData appendBytes:&sfloatBuffer length:sizeof(sfloatBuffer)];
    return sfloatData;
}

#pragma mark - duint16 Read

- (NSString *)duint16StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    return [self uint16StringForValue:value decimalExponent:decimalExponent];
}

#pragma mark - duint16 Write

- (NSData *)duint16DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    return [self uint16DataForString:string decimalExponent:decimalExponent error:error];
}

#pragma mark - String Read

- (NSString *)utf8StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
}

- (NSString *)utf16StringForValue:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    return [[NSString alloc] initWithData:value encoding:NSUTF16StringEncoding];
}

#pragma mark - String Write

- (NSData *)utf8DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)utf16DataForString:(NSString *)string decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    return [string dataUsingEncoding:NSUTF16StringEncoding];
}

#pragma mark - Encoded String 

- (NSString *)hexStringForData:(NSData *)value decimalExponent:(NSInteger)decimalExponent {
    NSMutableString *hexString = [[NSMutableString alloc] initWithString:@""];
    if (value.length) {
        const unsigned char *valueBuffer = value.bytes;
        for (unsigned index = 0; index < value.length; index++) {
            [hexString appendFormat:@"%02lX", (unsigned long)valueBuffer[index]];
        }
    }
    return [hexString copy];
}

- (NSString *)asciiStringForData:(NSData *)value {
    NSMutableString *asciiString = [[NSMutableString alloc] initWithString:@""];
    if (value.length) {
        NSString *ascii = [[NSString alloc] initWithData:value encoding:NSASCIIStringEncoding];
        [asciiString appendString:ascii];
    }
    return [asciiString copy];
}

- (NSString *)decimalStringForData:(NSData *)value {
    NSMutableString *decimalString = [[NSMutableString alloc] initWithString:@""];
    if (value.length) {
        const unsigned char *valueBuffer = value.bytes;
        for (unsigned index = 0; index < value.length; index++) {
            [decimalString appendFormat:@"%i", valueBuffer[index]];
            if (index + 1 < value.length) {
                [decimalString appendString:kDecimalDelimiter];
            }
        }
    }
    return decimalString;
}

#pragma mark - Encoding Data

///@return nil if poorly formatted string
- (NSData *)dataForHexString:(NSString *)hexString decimalExponent:(NSInteger)decimalExponent error:(NSError *__autoreleasing *)error {
    NSArray<NSString*>* hexPairs = [self parseIntoTwoCharactersSubstrings:hexString];
    NSMutableData * const data = [NSMutableData new];
    
    for (NSUInteger pairIndex = 0; pairIndex < hexPairs.count; pairIndex++) {
        NSString * const pair = hexPairs[pairIndex];
        NSString * const alignedPair = pair.length == 1 ? [NSString stringWithFormat:@"0%@", pair] : pair;
        const BOOL isLegalPair = [self isLegalHexString:alignedPair length:2];
        unsigned int pairValue;
        NSScanner * const pairScanner = [[NSScanner alloc] initWithString:alignedPair];
        [pairScanner scanHexInt:&pairValue];
        const BOOL isLegalPairValue = pairValue <= UINT8_MAX;
        
        if (isLegalPair && isLegalPairValue) {
            [data appendBytes:&pairValue length:sizeof(uint8_t)];
        } else {
            *error = [NSError errorWithDomain:ERROR_KIND_PARSE code:-1 userInfo:@{ @"errorKind": ERROR_KIND_PARSE }];
            return nil;
        }
    }
    return [data copy];
}

- (NSArray<NSString*>*)parseIntoTwoCharactersSubstrings:(NSString*)hexString {
    NSMutableArray<NSString*>* hexPairs = [[NSMutableArray alloc] init];
    
    NSMutableString* tmp = nil;
    for (int i = 0; i < hexString.length; i++) {
        NSString* currentCharacher = [NSString stringWithFormat: @"%C", [hexString characterAtIndex:i]];
        if (i % 2 == 0) {
            tmp = [[NSMutableString alloc] initWithString:currentCharacher];
        } else {
            [tmp appendString:currentCharacher];
            [hexPairs addObject:tmp];
            tmp = nil;
        }
    }

    if (tmp != nil) {
        [hexPairs addObject:tmp];
    }
    
    return hexPairs;
}

- (BOOL)isLegalHexString:(NSString *)hexPairString length:(NSUInteger)length {
    BOOL isRightSize = hexPairString.length == length;
    BOOL isLegalPair = YES && isRightSize;
    if (isRightSize) {
        for (NSUInteger subIndex = 0; subIndex < length; subIndex++) {
            NSString *charString = [hexPairString substringWithRange:NSMakeRange(subIndex, 1)];
            NSScanner *charScanner = [[NSScanner alloc] initWithString:charString];
            unsigned int charValue;
            isLegalPair = isLegalPair && [charScanner scanHexInt:&charValue];
        }
    }
    return isLegalPair;
}

///@return nil if poorly formatted string
- (NSData *)dataForAsciiString:(NSString *)asciiString {
    return [asciiString dataUsingEncoding:NSASCIIStringEncoding];
}

///@return nil if poorly formatted string
- (NSData *)dataForDecimalString:(NSString *)decimalString {
    NSArray *decimalStrings = [decimalString componentsSeparatedByString:kDecimalDelimiter];
    NSMutableData *data = [NSMutableData new];
    for (NSUInteger decimalIndex = 0; decimalIndex < decimalStrings.count; decimalIndex++) {
        NSString *decimalString = decimalStrings[decimalIndex];
        int decimalValue;
        NSScanner *decimalScanner = [[NSScanner alloc] initWithString:decimalString];
        BOOL isLegalDecimal = [decimalScanner scanInt:&decimalValue];
        isLegalDecimal = isLegalDecimal && decimalValue <= UINT8_MAX;
        if (isLegalDecimal) {
            [data appendBytes:&decimalValue length:sizeof(uint8_t)];
        } else {
            return nil;
        }
    }
    return data;
}

- (BOOL)isLegalDecimalString:(NSString *)decimalString {
    int decimalValue;
    NSScanner *decimalScanner = [[NSScanner alloc] initWithString:decimalString];
    BOOL isLegalDecimal = [decimalScanner scanInt:&decimalValue];
    return isLegalDecimal && decimalValue <= UINT8_MAX;
}

#pragma mark - Dictionary Setup

- (NSDictionary *)formatLengths {
    //format string -> # of bits to read for format
    return @{
             kBooleanFormat : @1,
             k2BitFormat : @2,
             kNibbleFormat : @4,
             k8BitFormat : @8,
             k16BitFormat : @16,
             k24BitFormat : @24,
             k32BitFormat : @32,
             kU8Format : @8,
             kU16Format : @16,
             kU24Format : @24,
             kU32Format : @32,
             kU40Format : @40,
             kU48Format : @48,
             kU64Format : @64,
             kU128Format : @128,
             kS8Format : @8,
             kS12Format : @12,
             kS16Format : @16,
             kS24Format : @24,
             kS32Format : @32,
             kS48Format : @48,
             kS64Format : @64,
             kS128Format : @128,
             kF32Format : @32,
             kF64Format : @64,
             kSFloatFormat : @16,
             kFloatFormat : @32,
             kDU16Format : @16,
             kU8StringFormat : @0,
             kU16StringFormat : @0,
             kRegCertFormat : @0,
             kVariableFormat : @0
             };
}

- (NSDictionary<NSString*, NSValue *> *)formatSelectors {
    //any format < 8 bits is not included here, but must be used with the byteArray method
    //format string -> string of selector to perform value extraction
    return @{
        k8BitFormat : [NSValue valueWithPointer:@selector(uint8StringForValue:decimalExponent:)],
        k16BitFormat : [NSValue valueWithPointer:@selector(uint16StringForValue:decimalExponent:)],
        k24BitFormat : [NSValue valueWithPointer:@selector(uint24StringForValue:decimalExponent:)],
        k32BitFormat : [NSValue valueWithPointer:@selector(uint32StringForValue:decimalExponent:)],
        kU8Format : [NSValue valueWithPointer:@selector(uint8StringForValue:decimalExponent:)],
        kU16Format : [NSValue valueWithPointer:@selector(uint16StringForValue:decimalExponent:)],
        kU24Format : [NSValue valueWithPointer:@selector(uint24StringForValue:decimalExponent:)],
        kU32Format : [NSValue valueWithPointer:@selector(uint32StringForValue:decimalExponent:)],
        kU40Format : [NSValue valueWithPointer:@selector(uint40StringForValue:decimalExponent:)],
        kU48Format : [NSValue valueWithPointer:@selector(uint48StringForValue:decimalExponent:)],
        kU64Format : [NSValue valueWithPointer:@selector(uint64StringForValue:decimalExponent:)],
        kU128Format : [NSValue valueWithPointer:@selector(uint128StringForValue:decimalExponent:)],
        kS8Format : [NSValue valueWithPointer:@selector(sint8StringForValue:decimalExponent:)],
        kS12Format : [NSValue valueWithPointer:@selector(sint12StringForValue:decimalExponent:)],
        kS16Format : [NSValue valueWithPointer:@selector(sint16StringForValue:decimalExponent:)],
        kS24Format : [NSValue valueWithPointer:@selector(sint24StringForValue:decimalExponent:)],
        kS32Format : [NSValue valueWithPointer:@selector(sint32StringForValue:decimalExponent:)],
        kS48Format : [NSValue valueWithPointer:@selector(sint48StringForValue:decimalExponent:)],
        kS64Format : [NSValue valueWithPointer:@selector(sint64StringForValue:decimalExponent:)],
        kS128Format : [NSValue valueWithPointer:@selector(sint128StringForValue:decimalExponent:)],
        kF32Format : [NSValue valueWithPointer:@selector(float32StringForValue:decimalExponent:)],
        kF64Format : [NSValue valueWithPointer:@selector(float64StringForValue:decimalExponent:)],
        kSFloatFormat : [NSValue valueWithPointer:@selector(sfloatStringForValue:decimalExponent:)],
        kFloatFormat : [NSValue valueWithPointer:@selector(floatStringForValue:decimalExponent:)],
        kDU16Format : [NSValue valueWithPointer:@selector(duint16StringForValue:decimalExponent:)],
        kU8StringFormat : [NSValue valueWithPointer:@selector(utf8StringForValue:decimalExponent:)],
        kU16StringFormat : [NSValue valueWithPointer:@selector(utf16StringForValue:decimalExponent:)],
        kRegCertFormat : [NSValue valueWithPointer:@selector(hexStringForData:decimalExponent:)],
        kVariableFormat : [NSValue valueWithPointer:@selector(hexStringForData:decimalExponent:)],
    };
}

- (NSDictionary<NSString*, NSValue *> *)dataSelectors {
    //any format < 8 bits is not included here, but must be used with the byteArray method
    //format string -> string of selector to perform value extraction
    return @{
        k8BitFormat : [NSValue valueWithPointer:@selector(uint8DataForString:decimalExponent:error:)],
        k16BitFormat : [NSValue valueWithPointer:@selector(uint16DataForString:decimalExponent:error:)],
        k24BitFormat : [NSValue valueWithPointer:@selector(uint24DataForString:decimalExponent:error:)],
        k32BitFormat : [NSValue valueWithPointer:@selector(uint32DataForString:decimalExponent:error:)],
        kU8Format : [NSValue valueWithPointer:@selector(uint8DataForString:decimalExponent:error:)],
        kU16Format : [NSValue valueWithPointer:@selector(uint16DataForString:decimalExponent:error:)],
        kU24Format : [NSValue valueWithPointer:@selector(uint24DataForString:decimalExponent:error:)],
        kU32Format : [NSValue valueWithPointer:@selector(uint32DataForString:decimalExponent:error:)],
        kU40Format : [NSValue valueWithPointer:@selector(uint40DataForString:decimalExponent:error:)],
        kU48Format : [NSValue valueWithPointer:@selector(uint48DataForString:decimalExponent:error:)],
        kU64Format : [NSValue valueWithPointer:@selector(uint64DataForString:decimalExponent:error:)],
        kU128Format : [NSValue valueWithPointer:@selector(uint128DataForString:decimalExponent:error:)],
        kS8Format : [NSValue valueWithPointer:@selector(sint8DataForString:decimalExponent:error:)],
        kS12Format : [NSValue valueWithPointer:@selector(sint12DataForString:decimalExponent:error:)],
        kS16Format : [NSValue valueWithPointer:@selector(sint16DataForString:decimalExponent:error:)],
        kS24Format : [NSValue valueWithPointer:@selector(sint24DataForString:decimalExponent:error:)],
        kS32Format : [NSValue valueWithPointer:@selector(sint32DataForString:decimalExponent:error:)],
        kS48Format : [NSValue valueWithPointer:@selector(sint48DataForString:decimalExponent:error:)],
        kS64Format : [NSValue valueWithPointer:@selector(sint64DataForString:decimalExponent:error:)],
        kS128Format : [NSValue valueWithPointer:@selector(sint128DataForString:decimalExponent:error:)],
        kF32Format : [NSValue valueWithPointer:@selector(float32DataForString:decimalExponent:error:)],
        kF64Format : [NSValue valueWithPointer:@selector(float64DataForString:decimalExponent:error:)],
        kSFloatFormat : [NSValue valueWithPointer:@selector(sfloatDataForString:decimalExponent:error:)],
        kFloatFormat : [NSValue valueWithPointer:@selector(floatDataForString:decimalExponent:error:)],
        kDU16Format : [NSValue valueWithPointer:@selector(duint16DataForString:decimalExponent:error:)],
        kU8StringFormat : [NSValue valueWithPointer:@selector(utf8DataForString:decimalExponent:error:)],
        kU16StringFormat : [NSValue valueWithPointer:@selector(utf16DataForString:decimalExponent:error:)],
        kRegCertFormat : [NSValue valueWithPointer:@selector(dataForHexString:decimalExponent:error:)],
        kVariableFormat : [NSValue valueWithPointer:@selector(dataForHexString:decimalExponent:error:)],
    };
}

- (int)exponentOfIntegerBaseForFloat:(Float32)number {
    int exponent;
    
    if (number == 0) {
        return 0;
    }
    
    if (fmodf(number, 10) == 0) {
        exponent = 0;
        while (fmodf(number, 10) == 0) {
            exponent++;
            number /= 10;
        }
    } else {
        exponent = 1;
        while (fmodf(number, 10) != 0) {
            exponent--;
            number *= 10;
        }
    }
    
    return exponent;
}

#pragma mark - Helpers

// There were several instances where we were attempting to cast the longValue of an NSNumber as an SInt64 e.g.
// SInt64 casted = (SInt64)[[self numberForString:string] longValue];
// This works for an app running in 64 bit mode, but not 32 bit mode. Therefore the following two methods are required.
- (SInt64)long64BitNumberForNumber:(NSNumber *)number appMode:(AppMode)appMode {
    SInt64 casted;
    switch ([self currentAppMode]) {
        case AppMode32Bit:
            casted = (SInt64)[number longLongValue];
            break;
        case AppMode64Bit:
            casted = (SInt64)[number longValue];
        default:
            break;
    }
    return casted;
}

- (uint64_t)unsignedLong64BitNumberForNumber:(NSNumber *)number appMode:(AppMode)appMode {
    uint64_t casted;
    switch ([self currentAppMode]) {
        case AppMode32Bit:
            casted = (uint64_t)[number unsignedLongLongValue];
            break;
        case AppMode64Bit:
            casted = (uint64_t)[number unsignedLongValue];
        default:
            break;
    }
    return casted;
}

// Based on the accepted answer here: http://stackoverflow.com/questions/20104403/determine-if-ios-device-is-32-or-64-bit
- (AppMode)currentAppMode {
    if (sizeof(void*) == 4) {
        return AppMode32Bit;
    } else if (sizeof(void*) == 8) {
        return AppMode64Bit;
    }
}

@end
