//
//  SILBitFieldFieldModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/29/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBitFieldFieldModel.h"
#import "SILBitRowModel.h"
#import "SILBluetoothBitModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILBluetoothBitFieldModel.h"
#import "SILCharacteristicFieldValueResolver.h"

@interface SILBitFieldFieldModel()

@property (strong, nonatomic) SILBluetoothFieldModel *fieldModel;
@property (strong, nonatomic) NSArray *bitRowFields;
@property (strong, nonatomic) NSData *readData; //what did we consume from value updates
@property (strong, nonatomic) NSData *writeData; //what do we want to write the value out as
@end

@implementation SILBitFieldFieldModel

@synthesize hideTopSeparator;
@synthesize delegate;
@synthesize requirementsSatisfied;
@synthesize parentCharacteristicModel;

- (instancetype)initBitFieldWithField:(SILBluetoothFieldModel *)fieldModel {
    self = [super init];
    if (self) {
        self.fieldModel = fieldModel;
        self.bitRowFields = [self initbitRowModels];
    }
    return self;
}

- (NSArray *)initbitRowModels {
    NSMutableArray *toggleRows = [NSMutableArray new];
    
    for (SILBluetoothBitModel *bitModel in self.fieldModel.bitfield.bits) {
        SILBitRowModel *bitRowModel = [[SILBitRowModel alloc] initWithBit:bitModel fieldModel:self.fieldModel];
        bitRowModel.parentCharacteristicModel = self.parentCharacteristicModel;
        [toggleRows addObject:bitRowModel];
    }
    
    return toggleRows;
}

- (NSArray *)bitRowModels {
    BOOL firstBit = YES;
    for (SILBitRowModel *bitModel in self.bitRowFields) {
        [bitModel setParentCharacteristicModel:self.parentCharacteristicModel];
        bitModel.hideTopSeparator = firstBit;
        if (firstBit) {
            firstBit = NO;
        }
    }
    return self.bitRowFields;
}

- (NSString *)primaryTitle {
    return @"Bit Field primary";
}

- (NSString *)secondaryTitle {
    return @"Bit field Secondary";
}

- (void)clearValues {
    [self consumeValue:[[NSData alloc] init] fromIndex:0];
}


//Consume a single bit value
- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index {
    NSData *bitFieldData = [[SILCharacteristicFieldValueResolver sharedResolver] subsectionOfData:value fromIndex:index forFormat:self.fieldModel.format];
    self.readData = bitFieldData;
    
    for (SILBitRowModel *bitModel in self.bitRowFields) {
        bitModel.delegate = self.delegate;
        [bitModel consumeValue:bitFieldData fromIndex:index];
    }
    
    return bitFieldData.length;
}

- (NSData *)dataForFieldWithError:(NSError * __autoreleasing *)error {
    NSMutableData * const bitFieldData = [NSMutableData new];
    const NSUInteger bitCount = [[SILCharacteristicFieldValueResolver sharedResolver] bitCountForFormat:self.fieldModel.format];
    uint8_t resultBuffer = 0;
    NSInteger bitIndex = bitCount - 1;
    
    while (bitIndex >= 0) {
        int bit = 0;
        if (bitIndex < self.bitRowFields.count) {
            SILBitRowModel *bitModel = self.bitRowFields[bitIndex];
            bit = [bitModel.toggleState intValue];
        }
        resultBuffer = resultBuffer | bit;
        if (bitIndex > 0) {
            resultBuffer = resultBuffer << 1;
        }
        bitIndex--;
    }
    
    [bitFieldData appendBytes:&resultBuffer length:1];
    
    return bitFieldData ?: self.readData;
}

@end
