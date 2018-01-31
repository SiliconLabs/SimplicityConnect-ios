//
//  SILHomeKitServiceTableModel.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILGenericAttributeTableModel.h"

@class HMService, SILCharacteristicTableModels;

@interface SILHomeKitServiceTableModel : NSObject <SILGenericAttributeTableModel>

@property (strong, nonatomic) HMService *service;
@property (strong, nonatomic) NSArray<SILCharacteristicTableModels *> *characteristicModels;

@property (strong, nonatomic) NSString *name;

- (instancetype)initWithService:(HMService *)service;

@end
