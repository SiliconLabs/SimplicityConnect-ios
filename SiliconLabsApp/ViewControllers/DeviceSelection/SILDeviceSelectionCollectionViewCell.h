//
//  SILDeviceSelectionCollectionViewCell.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/23/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const SILDeviceSelectionCollectionViewCellIdentifier;

@interface SILDeviceSelectionCollectionViewCell : UICollectionViewCell

@property (weak , nonatomic) IBOutlet UIImageView *signalImageView;
@property (weak, nonatomic) IBOutlet UIImageView *dmpTypeImageView;
@property (weak , nonatomic) IBOutlet UILabel *deviceNameLabel;

@end
