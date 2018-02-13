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
    NSData *fieldData = [[SILCharacteristicFieldValueResolver sharedResolver] subsectionOfData:value fromIndex:index forFormat:self.fieldModel.format];
    NSString *readValue = [[SILCharacteristicFieldValueResolver sharedResolver] readValueString:fieldData forFormat:self.fieldModel.format];
    self.primaryValue = readValue;
    self.readData = fieldData;
    [self.delegate didMeetRequirement:self.fieldModel.requirement];
    return fieldData.length;
}

- (NSData *)dataForField {
    self.writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:self.primaryValue asFormat:self.fieldModel.format];
    return self.writeData ?: self.readData;
}

@end
