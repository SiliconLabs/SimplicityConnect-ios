//
//  SILBluetoothXMLParser.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothXMLParser.h"
#import "XMLDictionary.h"
#import "SILBluetoothServiceModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "SILBluetoothDescriptorModel.h"
#import "SILBluetoothServiceCharacteristicModel.h"
#import "SILBluetoothFieldModel.h"
#import "SILBluetoothEnumerationModel.h"
#import "SILBluetoothBitModel.h"
#import "SILBluetoothBitFieldModel.h"
#import "SILDoubleKeyDictionaryPair.h"

const NSString * kNameAttributeKey = @"_name";
const NSString * kUuuidAttributeKey = @"_uuid";
const NSString * kTypeAttributeKey = @"_type";

@implementation SILBluetoothXMLParser

#pragma mark - Class Methods

+ (instancetype)sharedParser {
    static SILBluetoothXMLParser *sharedParser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedParser = [[SILBluetoothXMLParser alloc] init];
    });
    return sharedParser;
}

#pragma mark - Public Instance Methods

- (SILDoubleKeyDictionaryPair *)servicesDictionary {
    return [self dictionaryForDirectory:@"services" modelMaker:@selector(buildServiceFromXmlDictionary:)];
}

- (SILDoubleKeyDictionaryPair *)characteristicsDictionary {
    return [self dictionaryForDirectory:@"characteristics" modelMaker:@selector(buildCharacteristicFromXmlDictionary:)];
}

- (SILDoubleKeyDictionaryPair *)descriptorsDictionary {
    return [self dictionaryForDirectory:@"descriptors" modelMaker:@selector(buildDescriptorFromXmlDictionary:)];
}

#pragma mark - Services

- (SILBluetoothServiceModel *)buildServiceFromXmlDictionary:(NSDictionary *)xmlDict {
    NSString *serviceName = xmlDict[kNameAttributeKey];
    NSString *serviceSummary = [self bestAvailableSummary:xmlDict];
    NSString *serviceUuid = xmlDict[kUuuidAttributeKey];
    SILBluetoothServiceModel *serviceModel = [[SILBluetoothServiceModel alloc] initWithName:serviceName summary:serviceSummary uuid:serviceUuid];
    
    serviceModel.serviceCharacteristics = [self arrayForDictionary:xmlDict[@"Characteristics"] keyPath:@"Characteristic" selector:@selector(buildServiceCharacteristicFromXmlDictionary:)];
    
    return serviceModel;
}

#pragma mark - Characteristics

- (SILBluetoothCharacteristicModel *)buildCharacteristicFromXmlDictionary:(NSDictionary *)xmlDict {
    NSString *characteristicName = xmlDict[kNameAttributeKey];
    NSString *characteristicSummary = [self bestAvailableSummary:xmlDict];
    NSString *characteristicType = xmlDict[kTypeAttributeKey];
    NSString *characteristicUuid = xmlDict[kUuuidAttributeKey];
    SILBluetoothCharacteristicModel *characteristicModel = [[SILBluetoothCharacteristicModel alloc] initWithName:characteristicName summary:characteristicSummary type:characteristicType uuid:characteristicUuid];
    
    characteristicModel.fields = [self arrayForDictionary:xmlDict[@"Value"] keyPath:@"Field" selector:@selector(buildFieldFromXmlDictionary:)];
    
    return characteristicModel;
}

#pragma mark - Service Characteristics

- (SILBluetoothServiceCharacteristicModel *)buildServiceCharacteristicFromXmlDictionary:(NSDictionary *)xmlDict {
    NSString *name = xmlDict[kNameAttributeKey];
    NSString *type = xmlDict[kTypeAttributeKey];
    SILBluetoothServiceCharacteristicModel *serviceCharacteristicModel = [[SILBluetoothServiceCharacteristicModel alloc] initWithName:name type:type];

    serviceCharacteristicModel.descriptors = [self arrayForDictionary:xmlDict[@"Descriptors"] keyPath:@"Descriptor" selector:@selector(buildDescriptorFromXmlDictionary:)];
    
    return serviceCharacteristicModel;
}


#pragma mark - Fields

- (SILBluetoothFieldModel *)buildFieldFromXmlDictionary:(NSDictionary *)xmlDict {
    NSString *name = xmlDict[kNameAttributeKey];
    NSString *unit = xmlDict[@"Unit"];
    NSString *format = xmlDict[@"Format"];
    NSString *requires = xmlDict[@"Requirement"];
    SILBluetoothFieldModel *fieldModel = [[SILBluetoothFieldModel alloc] initWithName:name unit:unit format:format requires:requires];
    
    fieldModel.minimum = [xmlDict[@"Minimum"] integerValue];
    fieldModel.maximum = [xmlDict[@"Maximum"] integerValue];
    fieldModel.reference = xmlDict[@"Reference"];
    
    NSArray *bitModels = [self arrayForDictionary:xmlDict[@"BitField"] keyPath:@"Bit" selector:@selector(buildBitFromXmlDictionary:)];
    if (bitModels) {
        fieldModel.bitfield = [[SILBluetoothBitFieldModel alloc] initWithBits:bitModels];
    } else {
        fieldModel.enumerations = [self arrayForDictionary:xmlDict[@"Enumerations"] keyPath:@"Enumeration" selector:@selector(buildEnumerationFromXmlDictionary:)];
    }
    
    return fieldModel;
}

#pragma mark - Bits

- (SILBluetoothBitModel *)buildBitFromXmlDictionary:(NSDictionary *)xmlDict {
    NSInteger index = [xmlDict[@"_index"] integerValue];
    NSInteger size = [xmlDict[@"_size"] integerValue];
    NSString *name = xmlDict[kNameAttributeKey];
    SILBluetoothBitModel *bitModel = [[SILBluetoothBitModel alloc] initWithName:name index:index size:size];
    
    bitModel.enumerations = [self arrayForDictionary:xmlDict[@"Enumerations"] keyPath:@"Enumeration" selector:@selector(buildEnumerationFromXmlDictionary:)];
    
    return bitModel;
}

#pragma mark - Enumerations

- (SILBluetoothEnumerationModel *)buildEnumerationFromXmlDictionary:(NSDictionary *)xmlDict {
    NSInteger key = [xmlDict[@"_key"] integerValue];
    NSString *value = xmlDict[@"_value"];
    NSString *requires = xmlDict[@"_requires"];
    SILBluetoothEnumerationModel *enumerationModel = [[SILBluetoothEnumerationModel alloc] initWithKey:key value:value requires:requires];
    
    return enumerationModel;
}

#pragma mark - Descriptors

- (SILBluetoothDescriptorModel *)buildDescriptorFromXmlDictionary:(NSDictionary *)xmlDict {
    NSString *descriptorName = xmlDict[kNameAttributeKey];
    NSString *descriptorType = xmlDict[kTypeAttributeKey];
    NSString *descriptorUuid = xmlDict[kUuuidAttributeKey];
    SILBluetoothDescriptorModel *descriptorModel = [[SILBluetoothDescriptorModel alloc] initWithName:descriptorName type:descriptorType uuid:descriptorUuid];
    
    return descriptorModel;
}

#pragma mark - Helper Methods

- (SILDoubleKeyDictionaryPair *)dictionaryForDirectory:(NSString *)directoryName modelMaker:(SEL)modelMaker {
    SILDoubleKeyDictionaryPair *dictionary = [[SILDoubleKeyDictionaryPair alloc] init];
    
    NSError *error;
    NSString *directoryPath = [[SILBluetoothXMLParser sharedParser] filePathForDirectory:directoryName];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    
    for (NSString *fileName in directoryContents) {
        NSString *filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]];
        NSDictionary *xmlDict = [NSDictionary dictionaryWithXMLFile:filePath];
        NSString *modelTypeString = xmlDict[kTypeAttributeKey];
        NSString *modelUuidString = xmlDict[kUuuidAttributeKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [dictionary addObject:[self performSelector:modelMaker withObject:xmlDict] nameKey:modelTypeString idKey:modelUuidString];
#pragma clang diagnostic pop
    }
    
    return dictionary;
}


- (NSString *)filePathForDirectory:(NSString *)directory {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *directoryFormat = [NSString stringWithFormat:(@"XML/%@"), directory];
    NSString *directoryPath = [resourcePath stringByAppendingPathComponent:directoryFormat];
    return directoryPath;
}

- (NSString *)bestAvailableSummary:(NSDictionary *)xmlDict {
    if ([xmlDict[@"InformativeText"] isKindOfClass:[NSString class]]) {
        return xmlDict[@"InformativeText"];
    } else if ([xmlDict valueForKeyPath:@"InformativeText.Summary"]) {
        return [xmlDict valueForKeyPath:@"InformativeText.Summary"];
    } else if ([xmlDict valueForKeyPath:@"InformativeText.Abstract"]) {
        return [xmlDict valueForKeyPath:@"InformativeText.Abstract"];
    } else {
        return nil;
    }
}

- (NSArray *)arrayForDictionary:(NSDictionary *)xmlDict keyPath:(NSString *)keyPath selector:(SEL)modelMaker {
    NSMutableArray *models;
    NSArray *dicts = [xmlDict arrayValueForKeyPath:keyPath];
    for (NSDictionary *modelDict in dicts) {
        if (!models) {
            models = [[NSMutableArray alloc] init];
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [models addObject:[self performSelector:modelMaker withObject:modelDict]];
#pragma clang diagnostic pop
    }
    return [models copy];
}

@end
