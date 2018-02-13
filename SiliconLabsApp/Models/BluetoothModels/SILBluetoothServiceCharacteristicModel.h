//
//  SILBluetoothServiceCharacteristicModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothServiceCharacteristicModel : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSArray *descriptors;

- (instancetype)initWithName:(NSString *)name type:(NSString *)type;

@end
