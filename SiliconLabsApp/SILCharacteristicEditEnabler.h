//
//  SILCharacteristicEditEnabler.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/9/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILValueFieldRowModel, SILCharacteristicTableModel;


@protocol SILCharacteristicEditEnablerDelegate <NSObject>
- (void)beginValueEditWithValue:(SILValueFieldRowModel *)valueModel;
///@discussion: the save action block is the code tht should modify the model state, before that state is written to device
- (void)didSaveCharacteristic:(SILCharacteristicTableModel *)characteristicModel withAction:(void (^)(void))saveActionBlock;
@end