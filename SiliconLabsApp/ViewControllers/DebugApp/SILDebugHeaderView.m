//
//  SILDebugHeaderTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/5/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugHeaderView.h"
#import "UIColor+SILColors.h"

@interface SILDebugHeaderView()
@property (weak, nonatomic) IBOutlet UIView *contentBackground;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@end

@implementation SILDebugHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentBackground.backgroundColor = [UIColor sil_bgGreyColor];
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    self.dividerView.hidden = isIPad;
}

@end
