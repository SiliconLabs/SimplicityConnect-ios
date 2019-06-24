//
//  SILCharacteristicFieldValueResolver.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/27/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILCharacteristicFieldValueResolver.h"

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

@implementation SILCharacteristicFieldValueResolver

#pragma Init

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

- (NSData *)dataForValueString:(NSString *)string asFormat:(NSString *)format {
    NSString *dataSelector = [self dataSelectors][format];
    if (dataSelector) {
        SEL selector = NSSelectorFromString(dataSelector);
        if (selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [self performSelector:selector withObject:string];
#pragma clang diagnostic pop
        }
    }
    return [self dataForAsciiString:string];
}

#pragma mark - Read

- (NSString *)readValueString:(NSData *)value forFormat:(NSString *)format {
    if (value.length == 0) {
        return FieldReadErrorMessage;
    }
    
    NSString *formatSelector = [self formatSelectors][format];
    if (formatSelector) {
        SEL selector = NSSelectorFromString(formatSelector);
        if (selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [self performSelector:selector withObject:value];
#pragma clang diagnostic pop
        }
    }
    return [self utf8StringForValue:value];
}

#pragma mark - Write

- (NSNumber *)numberForString:(NSString *)string {
    return [self numberForString:string withSyle:NSNumberFormatterDecimalStyle];
}

- (NSNumber *)numberForString:(NSString *)string withSyle:(NSNumberFormatterStyle)style {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = style;
    NSNumber *number = [formatter numberFromString:string];
    return number;
}

#pragma mark -Binary Helpers

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

- (NSString *)uint8StringForValue:(NSData *)value {
    uint8_t result = *(uint8_t *)[value bytes];
    return [@(result) stringValue];
}

- (NSString *)uint16StringForValue:(NSData *)value {
    uint16_t *uint16Bytes = (uint16_t *)[value bytes];
    uint16_t result = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
    return [@(result) stringValue];
}

- (NSString *)uint24StringForValue:(NSData *)value {
    uint32_t *uint32Bytes = (uint32_t *)[value bytes];
    uint32_t full = (uint32_t)CFSwapInt32LittleToHost(*uint32Bytes);
    uint32_t result = full << 8 >> 8; //clean top bits
    return [@(result) stringValue];
}

- (NSString *)uint32StringForValue:(NSData *)value {
    uint32_t *uint32Bytes = (uint32_t *)[value bytes];
    uint32_t result = (uint32_t)CFSwapInt32LittleToHost(*uint32Bytes);
    return [@(result) stringValue];
}

- (NSString *)uint40StringForValue:(NSData *)value {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t full = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    uint64_t result = full << 24 >> 24; //clean top bits
    return [@(result) stringValue];
}

- (NSString *)uint48StringForValue:(NSData *)value {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t full = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    uint64_t result = full << 16 >> 16; //clean top bits
    return [@(result) stringValue];
}

- (NSString *)uint64StringForValue:(NSData *)value {
    uint64_t *uint64Bytes = (uint64_t *)[value bytes];
    uint64_t result = (uint64_t)CFSwapInt64LittleToHost(*uint64Bytes);
    return [@(result) stringValue];
}

- (NSString *)uint128StringForValue:(NSData *)value {
    return [self hexStringForData:value];
}

#pragma mark - Uint Write

- (NSData *)uint8DataForString:(NSString *)string {
    uint8_t casted = (uint8_t)[[self numberForString:string] unsignedIntValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)uint16DataForString:(NSString *)string {
    uint16_t casted = (uint16_t)[[self numberForString:string] unsignedIntValue];
    uint16_t result = (uint16_t)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)uint24DataForString:(NSString *)string {
    uint32_t casted = (uint32_t)[[self numberForString:string] unsignedIntValue];
    uint32_t result = (uint32_t)CFSwapInt32HostToLittle(casted);
    result = result << 8 >> 8;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 3)];
}

- (NSData *)uint32DataForString:(NSString *)string {
    uint32_t casted = (uint32_t)[[self numberForString:string] unsignedIntValue];
    uint32_t result = (uint32_t)CFSwapInt32HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)uint40DataForString:(NSString *)string {
    uint64_t casted = [self unsignedLong64BitNumberForNumber:[self numberForString:string] appMode:[self currentAppMode]];
    uint64_t result = (uint64_t)CFSwapInt64HostToLittle(casted);
    result = result << 24 >> 24;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 5)];
}

- (NSData *)uint48DataForString:(NSString *)string {
    uint64_t casted = [self unsignedLong64BitNumberForNumber:[self numberForString:string] appMode:[self currentAppMode]];
    uint64_t result = (uint64_t)CFSwapInt64HostToLittle(casted);
    result = result << 16 >> 16;
    return [NSData dataWithBytes:&result length:(sizeof(uint8_t) * 8)];
}

- (NSData *)uint64DataForString:(NSString *)string {
    uint64_t host = [self unsignedLong64BitNumberForNumber:[self numberForString:string] appMode:[self currentAppMode]];
    uint64_t little = (uint64_t)CFSwapInt64HostToLittle(host);
    return [NSData dataWithBytes:&little length:sizeof(uint64_t)];
}

- (NSData *)uint128DataForString:(NSString *)string {
    return [self dataForHexString:string];
}

#pragma mark - Sint Read

- (SInt64)sintCasterForSint:(SInt64)result originalSize:(int)originalSize castSize:(int)castSize {
    int sign = (result >> (originalSize - 1)) & 1;
    uint64_t mask = sign ? (UINT64_MAX << originalSize) : 0;
    result = result | mask;
    return result;
}

- (NSString *)sint8StringForValue:(NSData *)value {
    SInt8 result = *(SInt8 *)[value bytes];
    return [@(result) stringValue];
}

- (NSString *)sint12StringForValue:(NSData *)value {
    SInt16 *sint16Bytes = (SInt16 *)[value bytes];
    SInt16 result = (SInt16)CFSwapInt16LittleToHost(*sint16Bytes);
    result = result >> 4;
    result = (SInt16)[self sintCasterForSint:result originalSize:12 castSize:16];
    return [@(result) stringValue];
}

- (NSString *)sint16StringForValue:(NSData *)value {
    SInt16 *sint16Bytes = (SInt16 *)[value bytes];
    SInt16 result = (SInt16)CFSwapInt16LittleToHost(*sint16Bytes);
    return [@(result) stringValue];
}

- (NSString *)sint24StringForValue:(NSData *)value {
    SInt32 *sint32Bytes = (SInt32 *)[value bytes];
    SInt32 result = (SInt32)CFSwapInt32LittleToHost(*sint32Bytes);
    result = result << 8 >> 8; //clean up top bits from cast
    result = (SInt32)[self sintCasterForSint:result originalSize:24 castSize:32];
    return [@(result) stringValue];
}

- (NSString *)sint32StringForValue:(NSData *)value {
    SInt32 *sint32Bytes = (SInt32 *)[value bytes];
    SInt32 result = (SInt32)CFSwapInt32LittleToHost(*sint32Bytes);
    return [@(result) stringValue];
}

- (NSString *)sint48StringForValue:(NSData *)value {
    SInt64 *sint64Bytes = (SInt64 *)[value bytes];
    SInt64 result = (SInt64)CFSwapInt64LittleToHost(*sint64Bytes);
    result = result << 16 >> 16; //clean up top bits from cast
    result = (SInt64)[self sintCasterForSint:result originalSize:48 castSize:64];
    return [@(result) stringValue];
}

- (NSString *)sint64StringForValue:(NSData *)value {
    SInt64 *sint64Bytes = (SInt64 *)[value bytes];
    SInt64 result = (SInt64)CFSwapInt64LittleToHost(*sint64Bytes);
    return [@(result) stringValue];
}

//just return the string of the binary
- (NSString *)sint128StringForValue:(NSData *)value {
    return [self hexStringForData:value];
}

#pragma mark - Sint Write

- (NSData *)sint8DataForString:(NSString *)string {
    SInt8 casted = (SInt8)[[self numberForString:string] intValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)sint12DataForString:(NSString *)string {
    SInt16 casted = (SInt16)[[self numberForString:string] intValue];
    SInt16 result = (SInt16)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(casted)];
}

- (NSData *)sint16DataForString:(NSString *)string {
    SInt16 casted = (SInt16)[[self numberForString:string] intValue];
    SInt16 result = (SInt16)CFSwapInt16HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(casted)];
}

- (NSData *)sint24DataForString:(NSString *)string {
    SInt32 casted = (SInt32)[[self numberForString:string] intValue];
    SInt32 result = (SInt32)CFSwapInt32HostToLittle(casted);
    result = result << 8 >> 8;
    return [NSData dataWithBytes:&result length:(sizeof(SInt8) * 3)];
}

- (NSData *)sint32DataForString:(NSString *)string {
    SInt32 casted = (SInt32)[[self numberForString:string] intValue];
    SInt32 result = (SInt32)CFSwapInt32HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint48DataForString:(NSString *)string {
    SInt64 casted = [self long64BitNumberForNumber:[self numberForString:string] appMode:[self currentAppMode]];
    SInt64 result = (SInt64)CFSwapInt64HostToLittle(casted);
    result = result << 16 >> 16;
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint64DataForString:(NSString *)string {
    SInt64 casted = [self long64BitNumberForNumber:[self numberForString:string] appMode:[self currentAppMode]];
    SInt64 result = (SInt64)CFSwapInt64HostToLittle(casted);
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

- (NSData *)sint128DataForString:(NSString *)string {
    return [self dataForHexString:string];
}

#pragma mark - Float Read

- (NSString *)float32StringForValue:(NSData *)value {
    Float32 *float32Bytes = (Float32 *)[value bytes];
    Float32 result = (Float32)CFSwapInt32LittleToHost(*float32Bytes);
    return [@(result) stringValue];
}

- (NSString *)float64StringForValue:(NSData *)value {
    Float64 *float64Bytes = (Float64 *)[value bytes];
    Float64 result = (Float64)CFSwapInt64LittleToHost(*float64Bytes);
    return [@(result) stringValue];
}

- (NSString *)floatStringForValue:(NSData *)value {
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

- (NSData *)float32DataForString:(NSString *)string {
    Float32 casted = (Float32)[[self numberForString:string] floatValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}

- (NSData *)float64DataForString:(NSString *)string {
    Float64 casted = (Float64)[[self numberForString:string] floatValue];
    return [NSData dataWithBytes:&casted length:sizeof(casted)];
}


- (NSData *)floatDataForString:(NSString *)string {
    Float32 castedFloat = (Float32)[[self numberForString:string] floatValue];
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
- (NSString *)sfloatStringForValue:(NSData *)value {
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

#pragma mark - SFloat write

- (NSData *)sfloatDataForString:(NSString *)string {
    Float32 castedFloat = (Float32)[[self numberForString:string] floatValue];
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

- (NSString *)duint16StringForValue:(NSData *)value {
    return [self uint16StringForValue:value];
}

- (NSData *)duint16DataForString:(NSString *)string {
    return [self uint16DataForString:string];
}


#pragma mark - String Read

- (NSString *)utf8StringForValue:(NSData *)value {
    return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
}

- (NSString *)utf16StringForValue:(NSData *)value {
    return [[NSString alloc] initWithData:value encoding:NSUTF16StringEncoding];
}

#pragma mark - String Write

- (NSData *)utf8DataForString:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)utf16DataForString:(NSString *)string {
    return [string dataUsingEncoding:NSUTF16StringEncoding];
}

#pragma mark - Encoded String 

- (NSString *)hexStringForData:(NSData *)value {
    NSMutableString *hexString = [[NSMutableString alloc] initWithString:@""];
    if (value.length) {
        const unsigned char *valueBuffer = value.bytes;
        for (unsigned index = 0; index < value.length; index++) {
            [hexString appendFormat:@"%02lX", (unsigned long)valueBuffer[index]];
            if (index + 1 < value.length) {
                [hexString appendString:kHexDeilimiter];
            }
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
- (NSData *)dataForHexString:(NSString *)hexString {
    NSArray *hexPairs = [hexString componentsSeparatedByString:kHexDeilimiter];
    NSMutableData *data = [NSMutableData new];
    for (NSUInteger pairIndex = 0; pairIndex < hexPairs.count; pairIndex++) {
        NSString *pair = hexPairs[pairIndex];
        if (pair.length == 1) {
            pair = [NSString stringWithFormat:@"0%@", pair];
        }
        BOOL isLegalPair = [self isLegalHexString:pair length:2];
        unsigned int pairValue;
        NSScanner *pairScanner = [[NSScanner alloc] initWithString:pair];
        [pairScanner scanHexInt:&pairValue];
        isLegalPair = isLegalPair && pairValue <= UINT8_MAX;
        if (isLegalPair) {
            [data appendBytes:&pairValue length:sizeof(uint8_t)];
        } else {
            return nil;
        }
    }
    return [data copy];
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

- (NSDictionary *)formatSelectors {
    //any format < 8 bits is not included here, but must be used with the byteArray method
    //format string -> string of selector to perform value extraction
    return @{k8BitFormat : NSStringFromSelector(@selector(uint8StringForValue:)),
             k16BitFormat : NSStringFromSelector(@selector(uint16StringForValue:)),
             k24BitFormat : NSStringFromSelector(@selector(uint24StringForValue:)),
             k32BitFormat : NSStringFromSelector(@selector(uint32StringForValue:)),
             kU8Format : NSStringFromSelector(@selector(uint8StringForValue:)),
             kU16Format : NSStringFromSelector(@selector(uint16StringForValue:)),
             kU24Format : NSStringFromSelector(@selector(uint24StringForValue:)),
             kU32Format : NSStringFromSelector(@selector(uint32StringForValue:)),
             kU40Format : NSStringFromSelector(@selector(uint40StringForValue:)),
             kU48Format : NSStringFromSelector(@selector(uint48StringForValue:)),
             kU64Format : NSStringFromSelector(@selector(uint64StringForValue:)),
             kU128Format : NSStringFromSelector(@selector(uint128StringForValue:)),
             kS8Format : NSStringFromSelector(@selector(sint8StringForValue:)),
             kS12Format : NSStringFromSelector(@selector(sint12StringForValue:)),
             kS16Format : NSStringFromSelector(@selector(sint16StringForValue:)),
             kS24Format : NSStringFromSelector(@selector(sint24StringForValue:)),
             kS32Format : NSStringFromSelector(@selector(sint32StringForValue:)),
             kS48Format : NSStringFromSelector(@selector(sint48StringForValue:)),
             kS64Format : NSStringFromSelector(@selector(sint64StringForValue:)),
             kS128Format : NSStringFromSelector(@selector(sint128StringForValue:)),
             kF32Format : NSStringFromSelector(@selector(float32StringForValue:)),
             kF64Format : NSStringFromSelector(@selector(float64StringForValue:)),
             kSFloatFormat : NSStringFromSelector(@selector(sfloatStringForValue:)),
             kFloatFormat : NSStringFromSelector(@selector(floatStringForValue:)),
             kDU16Format : NSStringFromSelector(@selector(duint16StringForValue:)),
             kU8StringFormat : NSStringFromSelector(@selector(utf8StringForValue:)),
             kU16StringFormat : NSStringFromSelector(@selector(utf16StringForValue:)),
             kRegCertFormat : NSStringFromSelector(@selector(hexStringForData:)),
             kVariableFormat : NSStringFromSelector(@selector(hexStringForData:))
             };
}

- (NSDictionary *)dataSelectors {
    //any format < 8 bits is not included here, but must be used with the byteArray method
    //format string -> string of selector to perform value extraction
    return @{k8BitFormat : NSStringFromSelector(@selector(uint8DataForString:)),
             k16BitFormat : NSStringFromSelector(@selector(uint16DataForString:)),
             k24BitFormat : NSStringFromSelector(@selector(uint24DataForString:)),
             k32BitFormat : NSStringFromSelector(@selector(uint32DataForString:)),
             kU8Format : NSStringFromSelector(@selector(uint8DataForString:)),
             kU16Format : NSStringFromSelector(@selector(uint16DataForString:)),
             kU24Format : NSStringFromSelector(@selector(uint24DataForString:)),
             kU32Format : NSStringFromSelector(@selector(uint32DataForString:)),
             kU40Format : NSStringFromSelector(@selector(uint40DataForString:)),
             kU48Format : NSStringFromSelector(@selector(uint48DataForString:)),
             kU64Format : NSStringFromSelector(@selector(uint64DataForString:)),
             kU128Format : NSStringFromSelector(@selector(uint128DataForString:)),
             kS8Format : NSStringFromSelector(@selector(sint8DataForString:)),
             kS12Format : NSStringFromSelector(@selector(sint12DataForString:)),
             kS16Format : NSStringFromSelector(@selector(sint16DataForString:)),
             kS24Format : NSStringFromSelector(@selector(sint24DataForString:)),
             kS32Format : NSStringFromSelector(@selector(sint32DataForString:)),
             kS48Format : NSStringFromSelector(@selector(sint48DataForString:)),
             kS64Format : NSStringFromSelector(@selector(sint64DataForString:)),
             kS128Format : NSStringFromSelector(@selector(sint128DataForString:)),
             kF32Format : NSStringFromSelector(@selector(float32DataForString:)),
             kF64Format : NSStringFromSelector(@selector(float64DataForString:)),
             kSFloatFormat : NSStringFromSelector(@selector(sfloatDataForString:)),
             kFloatFormat : NSStringFromSelector(@selector(floatDataForString:)),
             kDU16Format : NSStringFromSelector(@selector(duint16DataForString:)),
             kU8StringFormat : NSStringFromSelector(@selector(utf8DataForString:)),
             kU16StringFormat : NSStringFromSelector(@selector(utf16DataForString:)),
             kRegCertFormat : NSStringFromSelector(@selector(dataForHexString:)),
             kVariableFormat : NSStringFromSelector(@selector(dataForHexString:))
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
