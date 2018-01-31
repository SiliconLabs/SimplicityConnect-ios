//
//  SILValueResolverTests.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/2/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SILCharacteristicFieldValueResolver.h"

@interface SILCharacteristicFieldValueResolver()
- (SInt64)sintCasterForSint:(SInt64)result originalSize:(int)originalSize castSize:(int)castSize;
@end

@interface SILValueResolverTests : XCTestCase
@end

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

@implementation SILValueResolverTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - NSData Bug

- (void)testGetBytesSuccess {
    uint16_t target = 0x9ab0;
    uint16_t bytes[1] = {0x9ab0};
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:2];
    uint16_t number;
    [testData getBytes:&number length:sizeof(number)];
    XCTAssertTrue(number == target);
}

- (void)testGetBytesFailue_MultiValue {
    uint16_t target = 0x9ab0;
    char bytes[2] = {0x9a,0xb0};
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:2];
    uint16_t number;
    [testData getBytes:&number length:sizeof(number)];
    XCTAssertFalse(number == target);
}

- (void)testGetManyBytesFailure {
    uint32_t target = 0x9ab0f376;
    char bytes[4] = {0x9a,0xb0,0xf3,0x76};
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:4];
    uint32_t number;
    [testData getBytes:&number length:sizeof(number)];
    XCTAssertFalse(number == target);
}

- (void)testDirectCastSuccess {
    uint16_t target = 0x9ab0;
    uint16_t bytes[1] = {0x9ab0};
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:2];

    uint16_t *uint16Bytes = (uint16_t *)[testData bytes];
    uint16_t number = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
    
    XCTAssertTrue(number == target);
}

- (void)testDirectCastBytesFailure_MultiValue {
    uint16_t target = 0x9ab0;
    char bytes[2] = {0x9a,0xb0};
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:2];
    
    uint16_t *uint16Bytes = (uint16_t *)[testData bytes];
    uint16_t number = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
    
    XCTAssertFalse(number == target);
}

#pragma mark - boolean

- (void)testSingleBitBooleanSuccess_False {
    char bytes[1] = { 0x00 };
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:1];

    NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:kBooleanFormat];
    BOOL result = [binaryArray[0] boolValue];
    
    XCTAssertNotNil(binaryArray);
    XCTAssertFalse(result);
}

- (void)testSingleBitBooleanSuccess_True {
    char bytes[1] = { 0x01 };
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:1];
    
    NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:kBooleanFormat];
    BOOL result = [binaryArray[0] boolValue];
    
    XCTAssertNotNil(binaryArray);
    XCTAssertTrue(result);
}

#pragma mark - 2bit

- (void)test1BitSuccess {
    char bytes[1] = { 0x01 };
    NSMutableData *testData = [NSMutableData new];
    [testData appendBytes:bytes length:1];
    
    NSArray * binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:k2BitFormat];
    
    NSArray *expectedArray = @[@(1), @(0)];
    XCTAssertNotNil(binaryArray);
    XCTAssertTrue([binaryArray isEqual:expectedArray]);
}

#pragma mark - nibble

- (void)testNibble {
    char bytes[1] = {0x2};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:1];
    
    NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:data forFormat:kNibbleFormat];
    
    NSArray *expectedArray = @[@(0),@(1),@(0),@(0)];
    XCTAssertNotNil(binaryArray);
    XCTAssertTrue([binaryArray isEqual:expectedArray]);
}

- (void)testNibbleSubValue {
    char bytes[1] = {0xF3};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:1];
    
    NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:data forFormat:kNibbleFormat];
    
    NSArray *expectedArray = @[@(1),@(1),@(0),@(0)];
    XCTAssertTrue(binaryArray);
    XCTAssertTrue([binaryArray isEqual:expectedArray]);
}

#pragma mark - uint8

- (void)testUint8 {
    uint8_t bytes[1] = {0b11101001};
    XCTAssertTrue([self assertBytes:bytes ofLength:1 areEqualToExpected:@"233" forFormat:kU8Format]);
}

- (void)testWriteUint8 {
    uint8_t target = 13;
    uint8_t written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"13" asFormat:kU8Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertTrue(target == written);
}

#pragma mark - uint16

- (void)testUint16 {
    uint16_t bytes[1] = {0b1010100111010100};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"43476" forFormat:kU16Format]);
}

- (void)testUint16_Zero {
    uint16_t bytes[1] = {0x0000};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"0" forFormat:kU16Format]);
}

- (void)testUint16_Nil {
    NSString *convertedValue = [[SILCharacteristicFieldValueResolver sharedResolver] readValueString:nil forFormat:kU16Format];
    XCTAssertTrue(convertedValue && [FieldReadErrorMessage isEqualToString:convertedValue]);
}

- (void)testWriteUint16 {
    uint16_t target = 356;
    uint16_t written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"356" asFormat:kU16Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - uint24

- (void)testUint24 {
    uint32_t bytes[1] = {0b101010100111110011010011};
    XCTAssertTrue([self assertBytes:bytes ofLength:3 areEqualToExpected:@"11173075" forFormat:kU24Format]);
}

- (void)testWriteUint24 {
    uint32_t target = 11173075;
    uint32_t written = 0;
    char sizeBuffer[3];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"11173075" asFormat:kU24Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = written << 8 >> 8;
    
    XCTAssertEqual(target, written);
}

#pragma mark - uint32

- (void)testUint32 {
    uint32_t bytes[1] = {0b10011110101001111100110100110110};
    XCTAssertTrue([self assertBytes:bytes ofLength:4 areEqualToExpected:@"2661797174" forFormat:kU32Format]);
}

- (void)testWriteUint32 {
    uint32_t target = 2661797174;
    uint32_t written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"2661797174" asFormat:kU32Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - uint40

- (void)testUint40 {
    uint64_t bytes[1] = {0b1011011110101111100111110010110100110110};
    XCTAssertTrue([self assertBytes:bytes ofLength:5 areEqualToExpected:@"788925459766" forFormat:kU40Format]);
}

- (void)testWriteUint40 {
    uint64_t target = 788925459766;
    uint64_t written = 0;
    char sizeBuffer[5];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"788925459766" asFormat:kU40Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = written << 24 >> 24;
    
    XCTAssertEqual(target, written);
}

#pragma mark - uint48

- (void)testUint48 {
    uint64_t bytes[1] = {0b101101111010111110011111001110000110110100110110};
    XCTAssertTrue([self assertBytes:bytes ofLength:6 areEqualToExpected:@"201964918435126" forFormat:kU48Format]);
}

- (void)testWriteUint48 {
    uint64_t target = 201964918435126;
    uint64_t written = 0;
    char sizeBuffer[6];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"201964918435126" asFormat:kU48Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = written << 16 >> 16;
    
    XCTAssertEqual(target, written);
}

#pragma mark - uint64

- (void)testUint64 {
    uint64_t bytes[1] = {0xB7AF9FDB926DB800};
    XCTAssertTrue([self assertBytes:bytes ofLength:8 areEqualToExpected:@"13235973595268495360" forFormat:kU64Format]);
}

- (void)testWriteUint64 {
    uint64_t target = 13235973595268495360;
    uint64_t written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"13235973595268495360" asFormat:kU64Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}


#pragma mark - uint128

- (void)testReadUint128 {
    char bytes[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
    NSString *writtenString = @"00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF";
    
    [self assertBytes:bytes ofLength:16 areEqualToExpected:writtenString forFormat:kU128Format];
}

#pragma mark - sint8

- (void)testSint8_Negative {
    SInt8 bytes[1] = {0b10110000};
    XCTAssertTrue([self assertBytes:bytes ofLength:1 areEqualToExpected:@"-80" forFormat:kS8Format]);
}

- (void)testSint8_Positive {
    SInt8 bytes[1] = {0b01111000};
    XCTAssertTrue([self assertBytes:bytes ofLength:1 areEqualToExpected:@"120" forFormat:kS8Format]);
}

- (void)testWriteSint8_Negative {
    SInt8 target = -80;
    SInt8 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-80" asFormat:kS8Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint8_Positive {
    uint64_t target = 120;
    uint64_t written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"120" asFormat:kS8Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint12

- (void)testSint12Conversion {
    SInt16 bytes[1] = {0x9ab0};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"-1621" forFormat:kS12Format]);
}

- (void)testSint12ConversionDropEnd {
    SInt16 bytes[1] = {0b1001101010110110};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"-1621" forFormat:kS12Format]);
}

- (void)testSint12_Positive {
    SInt16 bytes[1] = {0b0111110111000000};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"2012" forFormat:kS12Format]);
}

- (void)testWriteSint12_Negative {
    SInt16 target = -1621;
    SInt16 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-1621" asFormat:kS12Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint12_Positive {
    SInt16 target = 2012;
    SInt16 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"2012" asFormat:kS12Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint16

- (void)testSint16_Negative {
    SInt16 bytes[1] = {0b1111100011010001};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"-1839" forFormat:kS16Format]);
}

- (void)testSint16_Positive {
    SInt16 bytes[1] = {0b0000011110001010};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"1930" forFormat:kS16Format]);
}

- (void)testWriteSint16_Negative {
    SInt16 target = -1839;
    SInt16 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-1839" asFormat:kS16Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint16_Positive {
    SInt16 target = 1930;
    SInt16 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"1930" asFormat:kS16Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint24

- (void)testSint24_Negative {
    SInt32 bytes[1] = {0b111100110011010011010011};
    XCTAssertTrue([self assertBytes:bytes ofLength:4 areEqualToExpected:@"-838445" forFormat:kS24Format]);
}

- (void)testSint24_Positive {
    SInt32 bytes[1] = {0b000010011011110011111000};
    XCTAssertTrue([self assertBytes:bytes ofLength:4 areEqualToExpected:@"638200" forFormat:kS24Format]);
}

- (void)testWriteSint24_Negative {
    SInt32 target = -838445;
    SInt32 written = 0;
    char sizeBuffer[3];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-838445" asFormat:kS24Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = (SInt32)[[SILCharacteristicFieldValueResolver sharedResolver] sintCasterForSint:written originalSize:24 castSize:32];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint24_Positive {
    SInt32 target = 638200;
    SInt32 written = 0;
    char sizeBuffer[3];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"638200" asFormat:kS24Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = (SInt32)[[SILCharacteristicFieldValueResolver sharedResolver] sintCasterForSint:written originalSize:24 castSize:32];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint32

- (void)testSint32_Negative {
    SInt32 bytes[1] = {0b11100101010001101111001000011011};
    XCTAssertTrue([self assertBytes:bytes ofLength:4 areEqualToExpected:@"-448335333" forFormat:kS32Format]);
}

- (void)testSint32_Positive {
    SInt32 bytes[1] = {0b00110010010110101111101111101101};
    XCTAssertTrue([self assertBytes:bytes ofLength:4 areEqualToExpected:@"844823533" forFormat:kS32Format]);
}

- (void)testWriteSint32_Negative {
    SInt32 target = -448335333;
    SInt32 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-448335333" asFormat:kS32Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint32_Positive {
    SInt32 target = 844823533;
    SInt32 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"844823533" asFormat:kS32Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint 48

- (void)testSint48_Negative {
    SInt64 bytes[1] = {0b101010111010011100110111000110110000011001101010};
    XCTAssertTrue([self assertBytes:bytes ofLength:6 areEqualToExpected:@"-92740304304534" forFormat:kS48Format]);
}

- (void)testSint48_Positive {
    SInt64 bytes[1] = {0b000110101011011101000010100101111010101100101111};
    XCTAssertTrue([self assertBytes:bytes ofLength:6 areEqualToExpected:@"29374398573359" forFormat:kS48Format]);
}

- (void)testWriteSint48_Negative {
    SInt64 target = -92740304304534;
    SInt64 written = 0;
    char sizeBuffer[6];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-92740304304534" asFormat:kS48Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = (SInt64)[[SILCharacteristicFieldValueResolver sharedResolver] sintCasterForSint:written originalSize:48 castSize:64];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint48_Positive {
    SInt64 target = 29374398573359;
    SInt64 written = 0;
    char sizeBuffer[6];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"29374398573359" asFormat:kS48Format];
    [writtenData getBytes:&written length:sizeof(sizeBuffer)];
    written = (SInt64)[[SILCharacteristicFieldValueResolver sharedResolver] sintCasterForSint:written originalSize:48 castSize:64];
    
    XCTAssertEqual(target, written);
}

#pragma mark - sint 64

- (void)testSint64_Negative {
    SInt64 bytes[1] = {0b1111010110101000000001011010111111110001111011100010010111011100};
    XCTAssertTrue([self assertBytes:bytes ofLength:8 areEqualToExpected:@"-745339485093485092" forFormat:kS64Format]);
}

- (void)testSint64_Positive {
    SInt64 bytes[1] = {0b0010000100111010001111011001000000010100011100000000000001100001};
    XCTAssertTrue([self assertBytes:bytes ofLength:8 areEqualToExpected:@"2394293840928309345" forFormat:kS64Format]);
}

- (void)testWriteSint64_Negative {
    SInt64 target = -745339485093485092;
    SInt64 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"-745339485093485092" asFormat:kS64Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

- (void)testWriteSint64_Positive {
    SInt64 target = 2394293840928309345;
    SInt64 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"2394293840928309345" asFormat:kS64Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target,written);
}

#pragma mark - sint 128

- (void)testReadSint128 {
    char bytes[16] = {0x11, 0x22, 0x22, 0x11, 0x44, 0x44, 0x33, 0x66, 0x66, 0x55, 0x99, 0x99, 0xAA, 0xAA, 0xBB, 0xCC};
    NSString *writtenString = @"11:22:22:11:44:44:33:66:66:55:99:99:AA:AA:BB:CC";
    
    [self assertBytes:bytes ofLength:16 areEqualToExpected:writtenString forFormat:kU128Format];
}

#pragma mark - float32

- (void)testWriteFloat32 {
    Float32 target = 15325.453f;
    Float32 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"15325.453" asFormat:kF32Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - float64

- (void)testWriteFloat64 {
    Float64 target = 43823842823.420f;
    Float64 written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:@"43823842823.420" asFormat:kF64Format];
    [writtenData getBytes:&written length:sizeof(written)];
    
    XCTAssertEqual(target, written);
}

#pragma mark - FLOAT

- (void)testWriteFloat_Positive {
    NSString *numberString = @"35722280"; //35722930 -> 35722928 because of precision loss, so test changed
    int32_t target = {0x01368204};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:4];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kFloatFormat];
    XCTAssertTrue([writtenData isEqualToData:targetData]);
}

- (void)testWriteFloat_PositiveDecimal {
    NSString *numberString = @"36.4";
    int32_t target = {0xFF00016C};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:4];
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kFloatFormat];
    XCTAssertTrue([writtenData isEqualToData:targetData]);
}

#pragma mark - SFLOAT

- (void)testSFloat_Positive {
    uint16_t bytes[1] = {0x0072};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"114" forFormat:kSFloatFormat]);
}

- (void)testSFloat_Positive2 {
    uint16_t bytes[1] = {0x3217};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"535000" forFormat:kSFloatFormat]);
}

- (void)testSFloat_PositiveDecimal {
    uint16_t bytes[1] = {0xD034};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"0.052" forFormat:kSFloatFormat]);
}

- (void)testSFloat_Negative {
    uint16_t bytes[1] = {0x1B22};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"-12460" forFormat:kSFloatFormat]);
}

- (void)testSFloat_NegativeDecimal {
    uint16_t bytes[1] = {0xAAAA};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"-0.001366" forFormat:kSFloatFormat]);
}

- (void)testSFloat_BorderValue1 {
    uint16_t bytes[1] = {0x0800};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"2047" forFormat:kSFloatFormat]);
}

- (void)testSFLoat_BorderValue2 {
    uint16_t bytes[1] = {0x0801};
    XCTAssertTrue([self assertBytes:bytes ofLength:2 areEqualToExpected:@"2047" forFormat:kSFloatFormat]);
}

- (void)testWriteSFloatString_Positive {
    NSString *numberString = @"114";
    SInt16 target = {0x0072};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:2];
    
    NSData *writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kSFloatFormat];
    XCTAssertTrue([writeData isEqualToData:targetData]);
}

- (void)testWriteSFloatString_Positive2 {
    NSString *numberString = @"535000";
    SInt16 target = {0x3217};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:2];
    
    NSData *writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kSFloatFormat];
    XCTAssertTrue([writeData isEqualToData:targetData]);
}

- (void)testWriteSFloatString_PositiveDecimal {
    NSString *numberString = @"0.052";
    SInt16 target = {0xD034};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:2];
    
    NSData *writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kSFloatFormat];
    XCTAssertTrue([writeData isEqualToData:targetData]);
}

- (void)testWriteSFloatString_Negative {
    NSString *numberString = @"-12460";
    SInt16 target = {0x1B22};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:2];
    
    NSData *writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kSFloatFormat];
    XCTAssertTrue([writeData isEqualToData:targetData]);
}

- (void)testWriteSFloatString_NegativeDecimal {
    NSString *numberString = @"-0.001366";
    SInt16 target = {0xAAAA};
    NSData *targetData = [[NSData alloc] initWithBytes:&target length:2];
    
    NSData *writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:numberString asFormat:kSFloatFormat];
    XCTAssertTrue([writeData isEqualToData:targetData]);
}

#pragma mark - dunit16

#pragma mark - utf8s

- (void)testWriteUtf8 {
    NSString *target = @"How 'bout them apples";
    NSString *written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:target asFormat:kU8StringFormat];
    written = [[NSString alloc] initWithData:writtenData encoding:NSUTF8StringEncoding];
    
    XCTAssert([written isEqualToString:target]);
}

#pragma mark - utf16s

- (void)testWriteUtf16 {
    NSString *template = @"I sure do love apples.";
    NSData *templateData = [template dataUsingEncoding:NSUTF16StringEncoding];
    NSString *target = [[NSString alloc] initWithData:templateData encoding:NSUTF16StringEncoding];
    NSString *written = 0;
    
    NSData *writtenData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:target asFormat:kU16StringFormat];
    written = [[NSString alloc] initWithData:writtenData encoding:NSUTF16StringEncoding];
    
    XCTAssert([written isEqualToString:target]);
}

#pragma mark - reg-cert-data-list

#pragma mark - variable

#pragma mark - Hex String encoding

- (void)testDataForHexSuccess {
    NSString *hexString = @"3A:55:0F:1B:4C";
    const char target[5] = {0x3a, 0x55, 0x0f, 0x1B, 0x4c};
    NSData *targetData = [NSData dataWithBytes:target length:sizeof(target)];
    
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:hexString];
    
    XCTAssertNotNil(stringData);
    XCTAssertTrue([targetData isEqual:stringData]);
}

- (void)testDataForHexFailure_BadPair {
    NSString *hexString = @"3T:55:0f:1B:4c";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:hexString];
    
    XCTAssertNil(stringData);
}

- (void)testDataForHexFailure_LongPair {
    NSString *hexString = @"365:55:0f:1B:4c";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:hexString];
    
    XCTAssertNil(stringData);
}

- (void)testDataForHexFailure_LeadingColon {
    NSString *hexString = @":3A:55:0f:1B:4c";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:hexString];
    
    XCTAssertNil(stringData);
}

- (void)testDataForHexFailure_BadColon {
    NSString *hexString = @"3T:55:0f:1B;4c";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:hexString];
    
    XCTAssertNil(stringData);
}

#pragma mark - Decimal String Encoding

- (void)testDecimalStringForDataSuccess {
    NSString *target = @"1 1";
    const char data[2] = {0x01, 0x01};
    NSData *targetData = [NSData dataWithBytes:data length:sizeof(data)];
    
    NSString *string = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:targetData];
    
    XCTAssertTrue([string isEqualToString:target]);
}

- (void)testDecimalStringForDataSuccess_2 {
    NSString *target = @"6 15";
    const char data[2] = {0x06, 0x0f};
    NSData *targetData = [NSData dataWithBytes:data length:sizeof(data)];
    
    NSString *string = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:targetData];
    
    XCTAssertTrue([string isEqualToString:target]);
}


- (void)testDataForDecimalSuccess {
    NSString *decimalString = @"128 30 1 19 35";
    const char target[5] = {128, 30, 1, 19, 35};
    NSData *targetData = [NSData dataWithBytes:target length:sizeof(target)];
    
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForDecimalString:decimalString];
    
    XCTAssertNotNil(stringData);
    XCTAssertTrue([targetData isEqual:stringData]);
}


- (void)testDataForDecimalFailure_TooBig {
    NSString *decimalString = @"128 356 1 19 35";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForDecimalString:decimalString];
    
    XCTAssertNil(stringData);
}

- (void)testDataForDecimalFailure_BadChars {
    NSString *decimalString = @"123 30 Dad 19 35";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForDecimalString:decimalString];
    
    XCTAssertNil(stringData);
}

- (void)testDataForDecimalFailure_NoSpace {
    NSString *decimalString = @"124329";
    NSData *stringData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForDecimalString:decimalString];

    XCTAssertNil(stringData);
}

#pragma mark - Utility Tests

- (void)testExponentPositive {
    Float32 number = 535000.0f;
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:number];
    
    XCTAssertTrue(exponent == 3);
}

- (void)testExponentLessThanOne {
    Float32 number = 0.052f;
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:number];
    
    XCTAssertTrue(exponent == -3);
}

- (void)testExponentZero {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:0];
    XCTAssertTrue(exponent == 0);
}

- (void)testExponentOne {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:1];
    XCTAssertTrue(exponent == 0);
}

- (void)testExponentTen {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:10];
    XCTAssertTrue(exponent == 1);
}

- (void)testExponentTwelve {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:12];
    XCTAssertTrue(exponent == 0);
}

- (void)testExponentTwenty {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:20];
    XCTAssertTrue(exponent == 1);
}

- (void)testExponentTwentyThree {
    int exponent = [[SILCharacteristicFieldValueResolver sharedResolver] exponentOfIntegerBaseForFloat:23];
    XCTAssertTrue(exponent == 0);
}

#pragma mark - Test Helpers

- (BOOL)assertBytes:(const void *)bytes ofLength:(int)length areEqualToExpected:(NSString *)expectedValue forFormat:(NSString *)format {
    NSMutableData *testData = [[NSMutableData alloc] initWithBytes:bytes length:length];
    
    NSString *convertedValue = [[SILCharacteristicFieldValueResolver sharedResolver] readValueString:testData forFormat:format];
    
    return convertedValue && [expectedValue isEqualToString:convertedValue];
}

@end

