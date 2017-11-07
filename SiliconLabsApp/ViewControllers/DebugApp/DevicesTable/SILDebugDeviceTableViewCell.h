//
//  SILDebugTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 9/30/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDiscoveredPeripheral.h"

@class SILDebugAdvDetailCollectionViewCell;

@protocol DebugDeviceCellDelegate <NSObject>

- (void)displayAdvertisementDetails:(UITableViewCell *)cell;
- (void)didTapToConnect:(UITableViewCell *)cell;

@end

@interface SILDebugDeviceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *deviceNameContainer;
@property (weak, nonatomic) IBOutlet UIView *advertisedInfoContainer;
@property (weak, nonatomic) IBOutlet UIButton *advertisementInfoButton;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UIImageView *connectionChevron;
@property (weak, nonatomic) IBOutlet UIImageView *loadingSpinnerImageView;
@property (weak, nonatomic) id<DebugDeviceCellDelegate> delegate;

- (void)configureAsOwner:(id<UICollectionViewDataSource>)owner withIndexPath:(NSIndexPath *)indexPath;
- (void)startConnectionAnimation;
- (void)stopConnectionAnimation;
- (void)configureAsEnabled:(BOOL)isEnabled connectable:(BOOL)connectable;
- (void)revealCollectionView;

@end
