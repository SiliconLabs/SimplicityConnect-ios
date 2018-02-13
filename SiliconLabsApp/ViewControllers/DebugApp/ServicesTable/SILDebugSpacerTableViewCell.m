//
//  SILDebugServicesSpacerTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/30/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugSpacerTableViewCell.h"
#import "UIColor+SILColors.h"

@interface SILDebugSpacerTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *spacerView;
@end

@implementation SILDebugSpacerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.spacerView.backgroundColor = [UIColor sil_bgGreyColor];
}

@end
