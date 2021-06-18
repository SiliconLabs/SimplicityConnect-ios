//
//  SILValueResolverSpec.m
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 24/02/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@import Quick;
@import Nimble;
#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldValueResolver.h"

QuickSpecBegin(SILValueResolverSpec)

NSString * const kBooleanFormat = @"boolean";
NSString * const k2BitFormat = @"2bit";
NSString * const kNibbleFormat = @"nibble";

#pragma mark - Test Helpers

describe(@"fo NSData bug", ^{
    
    context(@"too many bytes", ^{
        __block uint32_t target = 0x9ab0f376;
        __block uint32_t number;
        __block NSMutableData *testData;
        beforeEach(^{
            testData = [NSMutableData new];
        });
        
        it(@"should be get wrong bytes", ^{
            char bytes[4] = {0x9a,0xb0,0xf3,0x76};
            [testData appendBytes:bytes length:4];
            [testData getBytes:&number length:sizeof(number)];
            expect(number).notTo(equal(target));
        });
    });
    
    context(@"right count of bytes", ^{
        __block uint16_t target = 0x9ab0;
        __block uint16_t number;
        __block NSMutableData *testData;
        beforeEach(^{
            testData = [NSMutableData new];
        });
        
        it(@"should be get right bytes", ^{
            uint16_t bytes[1] = {0x9ab0};
            [testData appendBytes:bytes length:2];
            [testData getBytes:&number length:sizeof(number)];
            expect(number == target).to(beTrue());
        });
        
        
        it(@"should fail with multi value", ^{
            char bytes[2] = {0x9a,0xb0};
            [testData appendBytes:bytes length:2];
            [testData getBytes:&number length:sizeof(number)];
            expect(number == target).to(beFalse());
        });
        
        it(@"should fail with multi value", ^{
            char bytes[2] = {0x9a,0xb0};
            [testData appendBytes:bytes length:2];
            [testData getBytes:&number length:sizeof(number)];
            expect(number == target).to(beFalse());
        });
        
        it(@"should success with direct cast", ^{
            uint16_t bytes[1] = {0x9ab0};
            [testData appendBytes:bytes length:2];
            uint16_t *uint16Bytes = (uint16_t *)[testData bytes];
            number = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
            expect(number == target).to(beTrue());
        });
        
        it(@"should fail with casting multi value", ^{
            char bytes[2] = {0x9a,0xb0};
            [testData appendBytes:bytes length:2];
            uint16_t *uint16Bytes = (uint16_t *)[testData bytes];
            number = (uint16_t)CFSwapInt16LittleToHost(*uint16Bytes);
            expect(number == target).to(beFalse());
        });
    });
});

describe(@"for boolean values", ^{
    __block NSMutableData *testData;
    beforeEach(^{
        testData = [NSMutableData new];
    });
    
    it(@"should be false for 0x00 byte", ^{
        char bytes[1] = { 0x00 };
        [testData appendBytes:bytes length:1];

        NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:kBooleanFormat];
        BOOL result = [binaryArray[0] boolValue];
        
        expect(binaryArray).toNot(beNil());
        expect(result).to(beFalse());
    });
    
    it(@"should be true for 0x01 byte", ^{
        char bytes[1] = { 0x01 };
        [testData appendBytes:bytes length:1];

        NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:kBooleanFormat];
        BOOL result = [binaryArray[0] boolValue];
        
        expect(binaryArray).toNot(beNil());
        expect(result).to(beTrue());
    });
});

describe(@"for 2bit values", ^{
    __block NSMutableData *testData;
    beforeEach(^{
        testData = [NSMutableData new];
    });
    
    it(@"should be getting proper array", ^{
        char bytes[1] = { 0x01 };
        [testData appendBytes:bytes length:1];

        NSArray * binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:testData forFormat:k2BitFormat];

        NSArray *expectedArray = @[@(1), @(0)];
        expect(binaryArray).toNot(beNil());
        expect(binaryArray).to(equal(expectedArray));
    });
});

describe(@"for nibble values", ^{
    
    it(@"should be getting proper array", ^{
        char bytes[1] = {0x2};
        NSData *data = [[NSData alloc] initWithBytes:bytes length:1];

        NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:data forFormat:kNibbleFormat];

        NSArray *expectedArray = @[@(0),@(1),@(0),@(0)];
        expect(binaryArray).toNot(beNil());
        expect(binaryArray).to(equal(expectedArray));
    });
    
    it(@"should be getting proper array for subvalue", ^{
        char bytes[1] = {0xF3};
        NSData *data = [[NSData alloc] initWithBytes:bytes length:1];

        NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:data forFormat:kNibbleFormat];

        NSArray *expectedArray = @[@(1),@(1),@(0),@(0)];
        expect(binaryArray).toNot(beNil());
        expect(binaryArray).to(equal(expectedArray));
    });
});

QuickSpecEnd
