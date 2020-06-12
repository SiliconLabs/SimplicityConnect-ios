//
//  SILCharacteristicFieldRow.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/5/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILFieldRequirementEnforcer.h"
#import "SILBluetoothFieldModel.h"
@class SILCharacteristicTableModel;

@protocol SILCharacteristicFieldRow <NSObject>

@property (strong, nonatomic) SILCharacteristicTableModel *parentCharacteristicModel;
@property (strong, nonatomic, readonly) SILBluetoothFieldModel *fieldModel;
@property (nonatomic) BOOL hideTopSeparator; //TODO: move to generic attribute protocol
@property (strong, nonatomic) id<SILFieldRequirementEnforcer> delegate;
@property (nonatomic) BOOL requirementsSatisfied;

- (NSString *)primaryTitle;
- (NSString *)secondaryTitle;
- (NSInteger)consumeValue:(NSData *)value fromIndex:(NSInteger)index; //return read length
- (NSData *)dataForFieldWithError:(NSError * __autoreleasing *)error;
- (void)clearValues;

@end
