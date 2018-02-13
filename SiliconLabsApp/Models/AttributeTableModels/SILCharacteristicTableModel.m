//
//  SILCharacteristicTableModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILCharacteristicFieldBuilder.h"
#import "SILBluetoothModelManager.h"
#import "SILUUIDProvider.h"

#import <Crashlytics/Crashlytics.h>

@interface SILCharacteristicTableModel()
@property (strong, nonatomic) SILCharacteristicFieldBuilder *fieldBuilder;
@property (strong, nonatomic) NSMutableArray *requirementsMet;
@property (strong, nonatomic) NSData *lastReadValue;
@property (strong, nonatomic) NSData *writeValue;

@property (nonatomic, readwrite) BOOL canWrite;
@property (nonatomic) BOOL writeWithResponse;
@property (nonatomic) BOOL writeNoResponse;
@end

@implementation SILCharacteristicTableModel

@synthesize isExpanded;
@synthesize hideTopSeparator;

- (instancetype)initWithCharacteristic:(CBCharacteristic *)characteristic {
    self = [super init];
    if (self) {
        self.characteristic = characteristic;
        self.bluetoothModel = [[SILBluetoothModelManager sharedManager] characteristicModelForUUIDString:[self uuidString]];
        self.fieldBuilder = [[SILCharacteristicFieldBuilder alloc] init];
        self.fieldTableRowModels = [self.fieldBuilder characteristicModelValueAsFieldRows:self.bluetoothModel];
        self.requirementsMet = [[NSMutableArray alloc] initWithArray:@[@"Mandatory"]];
        self.writeWithResponse = self.characteristic.properties & CBCharacteristicPropertyWrite;
        self.writeNoResponse = self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse;
        self.canWrite =  self.writeWithResponse || self.writeNoResponse;
        self.isUnknown = NO;
    }
    return self;
}

- (NSString *)name {
    if (_bluetoothModel.name) {
        return _bluetoothModel.name;
    }
    NSString* predefinedName = [SILUUIDProvider predefinedNameForServiceOrCharacteristicUUID:[self uuidString]];
    return predefinedName ?: @"Unknown Characteristic";
}

#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return self.fieldTableRowModels.count > 0;
}

- (void)toggleExpansionIfAllowed {
    self.isExpanded = !self.isExpanded;
}

- (NSString *)uuidString {
    return self.characteristic.UUID.UUIDString;
}

#pragma mark - SILRequirementDelegate

- (void)didMeetRequirement:(NSString *)requirement {
    if (requirement && ![self.requirementsMet containsObject:requirement]) {
        [self.requirementsMet addObject:requirement];
    }
}

#pragma mark - Read

- (void)updateWithField:(id<SILCharacteristicFieldRow>)fieldModel {
    NSMutableArray *fields = [[NSMutableArray alloc] initWithArray:self.fieldTableRowModels];
    for (NSInteger fieldIndex = 0; fieldIndex < self.fieldTableRowModels.count; fieldIndex++) {
        SILBluetoothFieldModel *bluetoothField = self.fieldTableRowModels[fieldIndex];
        if ([bluetoothField isEqual:[fieldModel fieldModel]]) {
            fields[fieldIndex] = fieldModel;
        }
    }
}

- (void)updateRead:(CBCharacteristic *)characteristic {
    if (characteristic.value) {
        self.lastReadValue = characteristic.value;
        NSInteger readIndex = 0;
        
        [CrashlyticsKit setObjectValue:self.bluetoothModel.name forKey:@"characteristic_name"];
        [CrashlyticsKit setObjectValue:characteristic.value forKey:@"characteristic_value"];
        for (NSObject<SILCharacteristicFieldRow> *fieldRowModel in self.fieldTableRowModels) {
            NSString *fieldRequirement = fieldRowModel.fieldModel.requirement;
            fieldRowModel.delegate = self;
            if (!fieldRequirement || [self.requirementsMet containsObject:fieldRequirement]) {
                fieldRowModel.requirementsSatisfied = YES;
                [CrashlyticsKit setObjectValue:@(readIndex) forKey:@"read_index"];
                NSInteger readLength = [fieldRowModel consumeValue:self.lastReadValue fromIndex:readIndex];
                readIndex += readLength;
            } else {
                fieldRowModel.requirementsSatisfied = NO;
            }
        }
    }
}

#pragma mark - Write

- (void)setIfAllowedFullWriteValue:(NSData *)value {
    if (!self.bluetoothModel) {
        if (self.lastReadValue.length > 0) {
            NSMutableData *sizedData = [NSMutableData dataWithLength:self.lastReadValue.length];
            NSData *writableData = value.length <= sizedData.length ? value : [value subdataWithRange:NSMakeRange(0, sizedData.length)];
            [sizedData replaceBytesInRange:NSMakeRange(0, value.length) withBytes:writableData.bytes];
            self.writeValue = sizedData;
        } else {
            self.writeValue = value;
        }
    }
}

- (void)writeIfAllowedToPeripheral:(CBPeripheral *)peripheral {
    if (self.canWrite) {
        if (self.writeWithResponse) {
            [peripheral writeValue:[self dataToWrite] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        } else if (self.writeNoResponse) {
            [peripheral writeValue:[self dataToWrite] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

- (NSData *)dataToWrite {
    if (!self.bluetoothModel) {
        return self.writeValue ?: self.lastReadValue;
    }
    NSMutableData *data = [NSMutableData new];
    for (NSObject<SILCharacteristicFieldRow> *fieldModel in self.fieldTableRowModels) {
        NSString *fieldRequirement = fieldModel.fieldModel.requirement;
        if (!fieldRequirement || [self.requirementsMet containsObject:fieldRequirement]) {
            NSData *fieldData = [fieldModel dataForField];
            if (!fieldData) {
                return nil; //we want to avoid writing garbage
            } else {
                [data appendData:fieldData];
            }
        }
    }
    return data;
}

- (BOOL)isUnknown {
    self.isUnknown = YES;
    return self.bluetoothModel == nil && self.fieldTableRowModels.count == 0;
}

@end
