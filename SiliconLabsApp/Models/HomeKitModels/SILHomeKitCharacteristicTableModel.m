//
//  SILHomeKitCharacteristicTableModel.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif
#import "SILHomeKitCharacteristicTableModel.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILCharacteristicFieldBuilder.h"
#import "SILBluetoothModelManager.h"
#import <Crashlytics/Crashlytics.h>

@interface SILHomeKitCharacteristicTableModel()
@property (strong, nonatomic) SILCharacteristicFieldBuilder *fieldBuilder;
@property (strong, nonatomic) NSMutableArray *requirementsMet;
@property (strong, nonatomic) NSData *lastReadValue;
@property (strong, nonatomic) NSData *writeValue;

@property (nonatomic, readwrite) BOOL canWrite;
@property (nonatomic) BOOL writeWithResponse;
@property (nonatomic) BOOL writeNoResponse;
@end

@implementation SILHomeKitCharacteristicTableModel

@synthesize isExpanded;
@synthesize hideTopSeparator;

- (instancetype)initWithCharacteristic:(HMCharacteristic *)characteristic {
    self = [super init];
    if (self) {
        self.characteristic = characteristic;
    }
    return self;
}

- (NSString *)name {
    return self.characteristic.localizedDescription;
}

#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return NO;
}

- (void)toggleExpansionIfAllowed {
    self.isExpanded = !self.isExpanded;
}

- (NSString *)uuidString {
    return self.characteristic.uniqueIdentifier.UUIDString;
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

}

- (NSData *)dataToWrite {
    if (!self.bluetoothModel) {
        return self.writeValue ?: self.lastReadValue;
    }
    NSError *error = nil;
    NSMutableData *data = [NSMutableData new];
    for (NSObject<SILCharacteristicFieldRow> *fieldModel in self.fieldTableRowModels) {
        NSString *fieldRequirement = fieldModel.fieldModel.requirement;
        if (!fieldRequirement || [self.requirementsMet containsObject:fieldRequirement]) {
            NSData *fieldData = [fieldModel dataForFieldWithError:&error];
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
    return self.bluetoothModel == nil && self.fieldTableRowModels.count == 0;
}

@end
