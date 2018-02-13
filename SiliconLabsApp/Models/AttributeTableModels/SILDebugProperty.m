//
//  SILDebugProperty.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugProperty.h"
#import "UIImage+SILImages.h"

@implementation SILDebugProperty

+ (NSArray *)allProperties {
    return @[
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyBroadcast)]
                                                      title:@"BROADCAST"
                                                  imageName:SILImageNamePropertyBroadcast],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyRead)]
                                                      title:@"READ"
                                                  imageName:SILImageNamePropertyRead],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyNotify)]
                                                      title:@"NOTIFY"
                                                  imageName:SILImageNamePropertyNotify],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyIndicate)]
                                                      title:@"INDICATE"
                                                  imageName:SILImageNamePropertyIndicate],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyWrite)]
                                                      title:@"WRITE"
                                                  imageName:SILImageNamePropertyWrite],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyWriteWithoutResponse)]
                                                      title:@"WRITE NO RESPONSE"
                                                  imageName:SILImageNamePropertyWriteNoResponse],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyAuthenticatedSignedWrites)]
                                                      title:@"SIGNED"
                                                  imageName:SILImageNamePropertySignedWrite],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyExtendedProperties)]
                                                      title:@"EXTENDED"
                                                  imageName:SILImageNamePropertyExtended],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyNotifyEncryptionRequired)]
                                                      title:@"NOTIFY ENCRPYTED"
                                                  imageName:nil],
             [[SILDebugProperty alloc] initWithPropertyKeys:@[@(CBCharacteristicPropertyIndicateEncryptionRequired)]
                                                      title:@"INDICATE ENCRYPTED"
                                                  imageName:nil]
             ];
}

+ (NSArray *)getActivePropertiesFrom:(CBCharacteristicProperties)properties {
    NSMutableArray *activeProperties = [[NSMutableArray alloc] init];
    for (SILDebugProperty *property in [SILDebugProperty allProperties]) {
        if ([property isActiveInProperties:properties]) {
            [activeProperties addObject:property];
        }
    }
    return activeProperties;
}

- (instancetype)initWithPropertyKeys:(NSArray *)keys
                               title:(NSString *)title
                           imageName:(NSString *)imageName {
    self = [super init];
    if (self) {
        self.keysForActivation = keys;
        self.title = title;
        self.imageName = imageName;
    }
    return self;
}

- (BOOL)isActiveInProperties:(CBCharacteristicProperties)properties {
    for (NSNumber *propertyKey in self.keysForActivation) {
        if (properties & [propertyKey unsignedIntValue]) {
            return YES;
        }
    }
    return NO;
}

@end
