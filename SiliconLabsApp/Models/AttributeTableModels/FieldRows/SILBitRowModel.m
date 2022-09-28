//
//  SILToggleTableRowModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBitRowModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILBluetoothBitFieldModel.h"
#import "SILBluetoothBitModel.h"
#import "SILBluetoothEnumerationModel.h"
#import "SILCharacteristicFieldValueResolver.h"
#import "NSData+Reverse.h"

@interface SILBitRowModel()

@property (strong, nonatomic, readwrite) SILBluetoothBitModel *bit;
@property (strong, nonatomic, readwrite) SILBluetoothFieldModel *fieldModel;
@property (strong, nonatomic) NSString *toggleValue;

@end

@implementation SILBitRowModel

@synthesize hideTopSeparator;
@synthesize delegate;
@synthesize requirementsSatisfied;
@synthesize parentCharacteristicModel;

- (instancetype)initWithBit:(SILBluetoothBitModel *)bit fieldModel:(SILBluetoothFieldModel *)fieldModel {
    self = [super init];
    if (self) {
        self.bit = bit;
        self.fieldModel = fieldModel;
        self.requirementsSatisfied = YES; //this is kind of a hack, they have to explicitly be set to NO due to some bug
    }
    return self;
}

- (NSString *)primaryTitle {
    if (self.toggleState == nil) {
        return nil;
    }
    
    return ((SILBluetoothEnumerationModel *)self.bit.enumerations[[self.toggleState intValue]]).value;
}

- (NSString *)secondaryTitle {
    return [NSString stringWithFormat: @"%@ - %@", self.fieldModel.name, self.bit.name];
}

- (NSString *)toggleValue {
    return ((SILBluetoothEnumerationModel *)self.bit.enumerations[[self.toggleState intValue]]).value;

}

//@discussion current implementation has this called by SILBitFieldFieldModel, which handles correct length
- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index {
    value = [self reverseDataIfNeeded:value];
    NSArray *binaryArray = [[SILCharacteristicFieldValueResolver sharedResolver] binaryArrayFromValue:value forFormat:self.fieldModel.format];
    
    if (self.bit.index < binaryArray.count) {
        NSNumber *binaryValue = binaryArray[self.bit.index];
        for (SILBluetoothEnumerationModel *enumerationModel in self.bit.enumerations) {
            if (enumerationModel.key == [binaryValue integerValue]) {
                self.toggleState = binaryValue;
                [self.delegate didMeetRequirement:enumerationModel.requires];
            }
        }
    } else {
        NSLog(@"Bit index is out of range");
    }
    
    return 0;
}

//BitField takes care of this for us
- (NSData *)dataForFieldWithError:(NSError * __autoreleasing *)error {
    return nil;
}

- (NSData *)reverseDataIfNeeded:(NSData *)fieldData {
    return self.fieldModel.invertedBytesOrder ? fieldData.reversed : fieldData;
}
@end
