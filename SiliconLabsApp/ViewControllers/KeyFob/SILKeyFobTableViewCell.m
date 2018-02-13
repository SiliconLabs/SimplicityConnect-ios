//
//  SILKeyFobTableViewCell.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/2/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILKeyFobTableViewCell.h"
#import "UIColor+SILColors.h"

@interface SILKeyFobTableViewCell ()

@property (weak, nonatomic) IBOutlet UIButton *findButton;

- (IBAction)didTapFindButton:(id)sender;

@end

@implementation SILKeyFobTableViewCell

- (void)setupFindButton {
    self.findButton.layer.borderColor = [UIColor sil_siliconLabsRedColor].CGColor;
    self.findButton.layer.borderWidth = 2.0;
}

- (void)setupLayoutMargins {
    // Prevent the cell from inheriting the Table View's margin settings
    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self setPreservesSuperviewLayoutMargins:NO];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupFindButton];
    [self setupLayoutMargins];
}

- (IBAction)didTapFindButton:(id)sender {
    [self.delegate didSelectFindMeWithKeyFobTableViewCell:self];
}

@end
