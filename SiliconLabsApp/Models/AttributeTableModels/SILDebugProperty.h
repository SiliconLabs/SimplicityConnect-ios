//
//  SILDebugProperty.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface SILDebugProperty : NSObject

@property (strong, nonatomic) NSArray *keysForActivation; //of CBCharacteristicProperties as NSNumbers
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *imageName;

+ (NSArray *)getActivePropertiesFrom:(CBCharacteristicProperties)properties;

@end
