//
//  SILDebugCharacteristicTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDebugProperty.h"
#import "SILGenericAttributeTableCell.h"
#import "BlueGecko.pch"

@class SILDebugCharacteristicTableViewCell;
@class SILCharacteristicTableModel;
#if ENABLE_HOMEKIT
@class SILHomeKitCharacteristicTableModel;
#endif

@protocol SILDebugCharacteristicCellDelegate <NSObject, SILMapCellDelegate>

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestReadForCharacteristic:(CBCharacteristic *)characteristic;
- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestWriteForCharacteristic:(CBCharacteristic *)characteristic;
- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestNotifyForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value;
- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestIndicateForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value;

@end

@interface SILDebugCharacteristicTableViewCell : UITableViewCell <SILGenericAttributeTableCell, SILMapCellProtocol>
@property (weak, nonatomic) id<SILDebugCharacteristicCellDelegate> delegate;
@property (weak, nonatomic) id<SILDescriptorTableViewCellDelegate> descriptorDelegate;
@property (weak, nonatomic) SILCharacteristicTableModel *characteristicTableModel;
@property (weak, nonatomic) IBOutlet UIButton *nameEditButton;

- (void)configureWithCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel;
#if ENABLE_HOMEKIT
- (void)configureWithHomeKitCharacteristicModel:(SILHomeKitCharacteristicTableModel *)homeKitCharacteristicModel;
#endif
@end
