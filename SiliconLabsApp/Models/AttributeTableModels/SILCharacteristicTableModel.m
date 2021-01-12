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
#import "SILLogDataModel.h"
#import "BlueGecko.pch"
#import "SILEncodingPseudoFieldRowModel.h"

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
@synthesize isMappable;

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
        self.canWrite = self.writeWithResponse || self.writeNoResponse;
        self.isMappable = NO;
    }
    return self;
}

- (NSString *)name {
    if (_bluetoothModel.name) {
        return _bluetoothModel.name;
    }
    
    NSString* predefinedName = [[SILUUIDProvider sharedProvider] predefinedNameForCharacteristicUUID:[self uuidString]];
    
    return predefinedName ?: self.mappedName;
}

- (NSString *)mappedName {
    [self setIsMappable:YES];
    NSString * const mappedName = [SILCharacteristicMap getWith:self.uuidString].name;
    return mappedName ?: [self setMappable];
}

- (NSString *)setMappable {
    return @"Unknown Characteristic";
}

- (BOOL)isUnknown {
    return self.bluetoothModel == nil && self.fieldTableRowModels.count == 0;
}

#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return self.fieldTableRowModels.count > 0;
}

- (void)toggleExpansionIfAllowed {
    self.isExpanded = !self.isExpanded;
}

- (void)expandFieldIfNeeded {
    self.isExpanded = YES;
}

- (NSString *)hexUuidString {
    return [self.characteristic getHexUuidValue];
}

- (NSString*)uuidString {
    return self.characteristic.UUID.UUIDString;
}

#pragma mark - SILRequirementDelegate

- (void)didMeetRequirement:(NSString *)requirement {
    if (requirement && ![self.requirementsMet containsObject:requirement]) {
        [self.requirementsMet addObject:requirement];
    }
}

#pragma mark - Read

- (void)readCharacteristicIfAllowed {
    if ((self.characteristic.properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead) {
        [self.characteristic.service.peripheral readValueForCharacteristic:self.characteristic];
    }
}

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
    if (self.isUnknown) {
        self.writeValue = value;
    }
}

- (BOOL)writeIfAllowedToPeripheral:(CBPeripheral *)peripheral withWriteType:(CBCharacteristicWriteType)writeType error:(NSError**)error {
    if (!self.canWrite) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"Characteristic is not writable" code:-1 userInfo:nil];
            [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"OTA writeToPeripheral: Characteristic is not writable " andPeripheral:peripheral andError:*error]];
        }
        return NO;
    }
    
    NSData * const dataToWrite = [self dataToWriteWithError:error];
    
    if (error != nil && *error) { return NO; }
    
    if (!dataToWrite) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"Data is out of range" code:-1 userInfo:nil];
            [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"OTA writeToPeripheral: Data is out of range " andPeripheral:peripheral andError:*error]];
        }
        return NO;
    }
    
    writeType = [self checkIfCharacteristicSupportsChosenWriteType:writeType];
    [peripheral writeValue:dataToWrite forCharacteristic:self.characteristic type:writeType];
    [self postRegisterLogNotification: [SILLogDataModel prepareLogDescriptionForWriteValueOfCharacteristic:self.characteristic andPeripheral:peripheral andError:*error andData:dataToWrite]];
        
    return YES;
}

- (CBCharacteristicWriteType)checkIfCharacteristicSupportsChosenWriteType:(CBCharacteristicWriteType)writeType {
    switch (writeType) {
        case CBCharacteristicWriteWithResponse:
            if (self.writeWithResponse == NO) {
                return CBCharacteristicWriteWithoutResponse;
            }
            break;
        case CBCharacteristicWriteWithoutResponse:
            if (self.writeNoResponse == NO) {
                return CBCharacteristicWriteWithResponse;
            }
            break;
        default:
            break;
    }
    
    return writeType;
}

- (NSData *)dataToWriteWithError:(NSError * __autoreleasing *)error {
    if (self.isUnknown) {
        return self.writeValue ?: self.lastReadValue;
    }
    
    return [self parseModelDataWithError:error];
}

- (NSData *)parseModelDataWithError:(NSError * __autoreleasing *)error {
    NSMutableData * const data = [NSMutableData new];
    
    for (NSObject<SILCharacteristicFieldRow> *fieldModel in self.fieldTableRowModels) {
        if (![self isFieldMetRequirement:fieldModel]) { continue; }

        NSData * const fieldData = [fieldModel dataForFieldWithError:error];

        if (*error) { return nil; }
            
        [data appendData:fieldData];
    }
    
    return [NSData dataWithData:data];
}

- (BOOL)isFieldMetRequirement:(NSObject<SILCharacteristicFieldRow> *)fieldModel {
    NSString * const fieldRequirement = fieldModel.fieldModel.requirement;
    
    return fieldRequirement && [self.requirementsMet containsObject:fieldRequirement];
}

- (void)postRegisterLogNotification:(NSString*)description {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationRegisterLog object:self userInfo:@{ @"description" : description}];
}

- (BOOL)clearModel {
    if (self.isUnknown) {
        return NO;
    }
    for (id<SILCharacteristicFieldRow> fieldRow in self.fieldTableRowModels) {        
        [fieldRow clearValues];
    }
    
    return YES;
}

@end
