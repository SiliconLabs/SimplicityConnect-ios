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
    }
    return self;
}

- (NSString *)primaryTitle {
    return self.primaryValue;
}

- (NSString *)secondaryTitle {
    return self.fieldModel.name;
}

- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index {
    SILCharacteristicFieldValueResolver * const valueResolver = [SILCharacteristicFieldValueResolver sharedResolver];
    NSData * const fieldData = [valueResolver subsectionOfData:value fromIndex:index forFormat:self.fieldModel.format];
    NSString * const readValue = [valueResolver readValueString:fieldData withFieldModel:self.fieldModel];
    self.primaryValue = readValue;
    self.readData = fieldData;
    [self.delegate didMeetRequirement:self.fieldModel.requirement];
    return fieldData.length;
}

- (NSData *)dataForFieldWithError:(NSError *__autoreleasing *)error {
    SILCharacteristicFieldValueResolver * const valueResolver = [SILCharacteristicFieldValueResolver sharedResolver];

    self.writeData = [valueResolver dataForValueString:self.primaryValue withFieldModel:self.fieldModel error:error];
    
    return self.writeData ?: self.readData;
}

@end
