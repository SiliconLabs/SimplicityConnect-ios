//
//  SILServiceModelManager.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBluetoothModelManager.h"
#import "SILBluetoothXMLParser.h"
#import "SILDoubleKeyDictionaryPair.h"

@interface SILBluetoothModelManager()

@property (nonatomic) BOOL populated;
@property (strong, nonatomic) SILDoubleKeyDictionaryPair *serviceModelDictionary;
@property (strong, nonatomic) SILDoubleKeyDictionaryPair *characteristicModelDictionary;
@property (strong, nonatomic) SILDoubleKeyDictionaryPair *descriptorModelDictionary;

@end

@implementation SILBluetoothModelManager

+ (instancetype)sharedManager {
    static SILBluetoothModelManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[SILBluetoothModelManager alloc] init];
    });
    return sharedManager;
}

- (void)populateModels {
    if (!self.populated) {
        self.serviceModelDictionary = [[SILBluetoothXMLParser sharedParser] servicesDictionary];
        self.characteristicModelDictionary = [[SILBluetoothXMLParser sharedParser] characteristicsDictionary];
        self.descriptorModelDictionary = [[SILBluetoothXMLParser sharedParser] descriptorsDictionary];
        self.populated = YES;
    }
}

- (SILBluetoothServiceModel *)serviceModelForUUIDString:(NSString *)string {
    return [self.serviceModelDictionary objectForIdKey:string];
}

- (SILBluetoothCharacteristicModel *)characteristicModelForUUIDString:(NSString *)string {
    return [self.characteristicModelDictionary objectForIdKey:string];
}

- (SILBluetoothCharacteristicModel *)characteristicModelForName:(NSString *)string {
    return [self.characteristicModelDictionary objectForNameKey:string];
}

- (SILBluetoothDescriptorModel *)descriptorModelForUUIDString:(NSString *)string {
    return [self.descriptorModelDictionary objectForIdKey:string];
}

- (SILBluetoothDescriptorModel *)descriptorModelForName:(NSString *)string {
    return [self.descriptorModelDictionary objectForNameKey:string];
}

@end
