//
//  SILFieldTableModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILCharacteristicFieldBuilder.h"
#import "SILBitRowModel.h"
#import "SILEnumerationFieldRowModel.h"
#import "SILValueFieldRowModel.h"
#import "SILBitFieldFieldModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "SILBluetoothModelManager.h"

@interface SILCharacteristicFieldBuilder()

@property (strong, nonatomic) NSDictionary *formatLengths;

@end

@implementation SILCharacteristicFieldBuilder

+ (instancetype)sharedBuilder {
    static SILCharacteristicFieldBuilder *sharedBuilder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBuilder = [[SILCharacteristicFieldBuilder alloc] init];
    });
    return sharedBuilder;
}

- (NSArray *)characteristicModelValueAsFieldRows:(SILBluetoothCharacteristicModel *)characteristicModel withRequirements:(NSArray<NSString *> *)requirements {
    NSMutableArray *allFieldsModels = [NSMutableArray new];
    
    for (SILBluetoothFieldModel *fieldModel in characteristicModel.fields) {
        NSArray *fieldTableRowModels = [self fieldTableRowsForFieldModel:fieldModel];
        [allFieldsModels addObjectsFromArray:fieldTableRowModels];
    }
    if (requirements != nil) {
        for (id<SILCharacteristicFieldRow> fieldRow in allFieldsModels) {
            fieldRow.fieldModel.requirements = [requirements copy];
        }
    }
    
    return [allFieldsModels copy];
}

- (NSArray *)fieldTableRowsForFieldModel:(SILBluetoothFieldModel *)fieldModel {
    NSMutableArray *mutableFieldTableRows = [NSMutableArray new];
    
    if (fieldModel.reference) {
        SILBluetoothCharacteristicModel *referenceModel = [[SILBluetoothModelManager sharedManager] characteristicModelForName:fieldModel.reference];
        return [self characteristicModelValueAsFieldRows:referenceModel withRequirements:fieldModel.requirements];
    }
    
    if (!fieldModel.format) {
        return [mutableFieldTableRows copy];//ignore for now
    }
    
    if (fieldModel.bitfield) {
        return @[[[SILBitFieldFieldModel alloc] initBitFieldWithField:fieldModel]]; //[SILBitRowModel bitRowModelsField:fieldModel];
    } else if (fieldModel.enumerations) {
        return @[[[SILEnumerationFieldRowModel alloc] initWithField:fieldModel]];
    } else {
        return @[[[SILValueFieldRowModel alloc] initWithField:fieldModel]];
    }
    
    return [mutableFieldTableRows copy];
}

@end
