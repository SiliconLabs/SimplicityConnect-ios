//
//  SILEnumerationFieldRow.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILEnumerationFieldRowModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILCharacteristicFieldValueResolver.h"
#import "SILBluetoothEnumerationModel.h"

@interface SILEnumerationFieldRowModel()

@property (strong, nonatomic, readwrite) NSArray *enumertations;
@property (strong, nonatomic, readwrite) SILBluetoothFieldModel *fieldModel;
@property (strong, nonatomic) NSData *readData; //what did we consume from value updates
@property (strong, nonatomic) NSData *writeData; //what do we want to write the value out as
@end

@implementation SILEnumerationFieldRowModel

@synthesize hideTopSeparator;
@synthesize delegate;
@synthesize requirementsSatisfied;
@synthesize parentCharacteristicModel;

- (instancetype)initWithField:(SILBluetoothFieldModel *)fieldModel {
    self = [super init];
    if (self) {
        self.fieldModel = fieldModel;
        self.enumertations = fieldModel.enumerations;
        self.requirementsSatisfied = YES; //this is kind of a hack, they have to explicitly be set to NO due to some bug
    }
    return self;
}

- (NSString *)primaryTitle {
    for (SILBluetoothEnumerationModel *enumerationModel in self.enumertations) {
        if (enumerationModel.key == (int)self.activeValue) {
            return enumerationModel.value;
        }
    }
    return @"Unknown Enumeration Value";
}

- (NSString *)secondaryTitle {
    return self.fieldModel.name;
}

- (void)clearValues {
    [self consumeValue:[[NSData alloc] init] fromIndex:0];
}

- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index {
    if (self.fieldModel.format) {
        NSData *fieldData = [[SILCharacteristicFieldValueResolver sharedResolver] subsectionOfData:value fromIndex:index forFormat:self.fieldModel.format];
        NSInteger readValue = [[[SILCharacteristicFieldValueResolver sharedResolver] readValueString:fieldData withFieldModel:self.fieldModel] integerValue];
        self.activeValue = readValue;
        self.readData = fieldData;
        [self.delegate didMeetRequirement:self.fieldModel.requirement];
        return fieldData.length;
    } else {
        NSLog(@"No format given");
        return 0;
    }
}

- (NSData *)dataForFieldWithError:(NSError * __autoreleasing *)error {
    self.writeData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForValueString:[@(self.activeValue) stringValue] withFieldModel:self.fieldModel error:error];
    return self.writeData ?: self.readData;
}

@end
