//
//  SILValueFieldTableRowModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILValueFieldRowModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILCharacteristicFieldValueResolver.h"
#import "NSData+Reverse.h"

@interface SILValueFieldRowModel()

@property (strong, nonatomic, readwrite) SILBluetoothFieldModel *fieldModel;
@property (strong, nonatomic) NSData *readData; //what did we consume from value updates
@property (strong, nonatomic) NSData *writeData; //what do we want to write the value out as

@end

@implementation SILValueFieldRowModel

@synthesize hideTopSeparator;
@synthesize delegate;
@synthesize requirementsSatisfied;
@synthesize parentCharacteristicModel;

- (instancetype)initWithField:(SILBluetoothFieldModel *)fieldModel {
    self = [super init];
    if (self) {
        self.fieldModel = fieldModel;
        self.requirementsSatisfied = YES; //this is kind of a hack, they have to explicitly be set to NO due to some bug
        self.primaryValue = @"";
    }
    return self;
}

- (NSString *)primaryTitle {
    return self.primaryValue;
}

- (NSString *)secondaryTitle {
    return self.fieldModel.name;
}

- (void)clearValues {
    self.primaryValue = @"";
}

- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index {
    SILCharacteristicFieldValueResolver * const valueResolver = [SILCharacteristicFieldValueResolver sharedResolver];
    NSData * fieldData = [valueResolver subsectionOfData:value fromIndex:index forFieldModel:self.fieldModel];
    fieldData = [self reverseDataIfNeeded:fieldData];
    
    NSString * const readValue = [valueResolver readValueString:fieldData withFieldModel:self.fieldModel];
    self.primaryValue = readValue;
    self.readData = fieldData;
    return fieldData.length;
}

- (NSData *)dataForFieldWithError:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolver * const valueResolver = [SILCharacteristicFieldValueResolver sharedResolver];

    self.writeData = [valueResolver dataForValueString:self.primaryValue withFieldModel:self.fieldModel error:error];
    self.writeData = [self reverseDataIfNeeded:self.writeData];
    
    return self.writeData ?: self.readData;
}

- (NSData *)reverseDataIfNeeded:(NSData *)fieldData {
    return self.fieldModel.invertedBytesOrder ? fieldData.reversed : fieldData;
}

@end
