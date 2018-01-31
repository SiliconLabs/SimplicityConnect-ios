//
//  SILFieldTableModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILBluetoothFieldModel, SILBluetoothCharacteristicModel, SILCharacteristicTableModel;

@interface SILCharacteristicFieldBuilder : NSObject

- (NSArray *)characteristicModelValueAsFieldRows:(SILBluetoothCharacteristicModel *)characteristicModel;

@end
