//
//  SILAppSelectionCollectionViewCell.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILApp.h"

@interface SILAppSelectionCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *profileKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *profileValueLabel;

- (void)setFieldsInCell:(SILApp*)appData;
@end
