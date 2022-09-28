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

- (NSData *)subsectionOfData:(NSData *)value fromIndex:(NSInteger)index forFieldModel:(SILBluetoothFieldModel *)fieldModel {
    NSInteger byteCount = [[SILCharacteristicFieldValueResolver sharedResolver] byteCountForFormat:fieldModel.format withValue:value];
    
    if ([fieldModel.name isEqualToString:@"Sensor Status Annunciation"]) {
        byteCount = 3;
    }
    
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
    
    CharacteristicFieldConverter *test = [CharacteristicFieldConverter.alloc init];
    
    BOOL ok = [test supportsWithFieldModel:fieldModel];
    if (ok) {
        return [test convertToStringWithFieldModel:fieldModel value:value];
    } else {
        return [self utf8StringForValue:value decimalExponent:0];
    }
}

- (NSNumber *)applyDecimalExponent:(NSInteger)decimalExponent toNumber:(NSNumber *)number {
    NSDecimalNumber * const decimalNumber = [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
    
    return [decimalNumber decimalNumberByMultiplyingByPowerOf10:decimalExponent];
}

#pragma mark - Write

- (NSData *)dataForValueString:(NSString *)string withFieldModel:(SILBluetoothFieldModel *)fieldModel error:(NSError *__autoreleasing *)error {
    
    CharacteristicFieldConverter *test = [CharacteristicFieldConverter.alloc init];
    
    BOOL ok = [test supportsWithFieldModel:fieldModel];
    if (ok) {
        return [test convertToDataWithFieldModel:fieldModel value:string];
    } else {
        return [self dataForAsciiString:string];
    }
}

#pragma mark - Binary Helpers

- (NSArray *)binaryArrayFromValue:(NSData *)value forFormat:(NSString *)format {
    NSMutableArray *binaryArray = [NSMutableArray new];
    NSUInteger bitCount = [[self formatLengths][format] unsignedIntegerValue];
    NSUInteger byteSize = [self byteCountForFormat:format withValue:value];
    
    uint8_t *byteBlock = malloc(sizeof(uint8_t) * byteSize);
    [value getBytes:byteBlock length:byteSize];
    
    
    for (NSInteger byteIndex = 0; byteIndex < byteSize; byteIndex++) {
        uint8_t byte = byteBlock[byteIndex];
        NSInteger byteBitsCount = byteIndex == (byteSize - 1) && bitCount % 8 != 0 ? bitCount % 8 : 8;
        for (NSInteger bit = 0; bit < byteBitsCount; bit++) {
            int bitValue = (byte >> bit) & 1;
            [binaryArray addObject:@(bitValue)];
        }
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
        for(int i = 0; i < ascii.length; i++) {
            char character = [ascii characterAtIndex:i];
            if((int) character < 32 || (int) character > 126) {
                [asciiString appendString:@"\ufffd"];
            } else {
                [asciiString appendFormat:@"%c", character];
            }
        }
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
        if (decimalString.length > 3) {
            return nil;
        }
        if (decimalIndex == decimalStrings.count - 1 && decimalString.length == 0) {
            continue;
        }
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

@end
