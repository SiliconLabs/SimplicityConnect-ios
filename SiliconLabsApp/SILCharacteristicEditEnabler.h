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
- (BOOL)saveCharacteristic:(SILCharacteristicTableModel *)characteristicModel withWriteType:(CBCharacteristicWriteType)writeType error:(NSError **)error;

@end
