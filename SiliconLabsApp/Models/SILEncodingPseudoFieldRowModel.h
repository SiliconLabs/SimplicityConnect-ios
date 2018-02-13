//
// Created by Glenn Martin on 11/10/15.
// Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCharacteristicFieldRow.h"

@class SILBluetoothFieldModel;

@interface SILEncodingPseudoFieldRowModel : NSObject <SILCharacteristicFieldRow>
@property (strong, nonatomic, nonnull) SILCharacteristicTableModel *parentCharacteristicModel;
@property (strong, nonatomic, readonly, nullable) SILBluetoothFieldModel *fieldModel;
@property (nonatomic) BOOL hideTopSeparator; //TODO: move to generic attribute protocol
@property (strong, nonatomic, nullable) id<SILFieldRequirementEnforcer> delegate;
@property (nonatomic) BOOL requirementsSatisfied;

- (instancetype _Nonnull)initForCharacteristicModel:(SILCharacteristicTableModel * _Nonnull)model;

@end
