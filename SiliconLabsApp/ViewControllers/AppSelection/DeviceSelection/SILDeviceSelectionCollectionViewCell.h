//
//  SILDeviceSelectionCollectionViewCell.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/23/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const SILDeviceSelectionCollectionViewCellIdentifier;

@class SILApp;
@class SILDiscoveredPeripheral;
@class DiscoveredDeviceDisplay;

@interface SILDeviceSelectionCollectionViewCell : UICollectionViewCell

@property (weak , nonatomic) IBOutlet UIImageView *signalImageView;
@property (weak, nonatomic) IBOutlet UIImageView *dmpTypeImageView;
@property (weak , nonatomic) IBOutlet UILabel *deviceNameLabel;

- (void)configureCellForPeripheral:(SILDiscoveredPeripheral*)discoveredPeripheral andApplication:(SILApp*)app;
- (void)configureCellForThunderboardDevice:(DiscoveredDeviceDisplay *)device;

@end
