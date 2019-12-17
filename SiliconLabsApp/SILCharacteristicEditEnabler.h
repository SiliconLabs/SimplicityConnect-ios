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
- (void)saveCharacteristic:(SILCharacteristicTableModel *)characteristicModel error:(NSError **)error;

@end
