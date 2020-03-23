//
//  SILBeaconTypeTableViewCell.m
//  BlueGecko
//
//  Created by Kamil Czajka on 13/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBeaconTypeTableViewCell.h"

@interface SILBeaconTypeTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *beaconTypeName;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImage;

@end

@implementation SILBeaconTypeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setAppearance];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setAppearance {
    [self setFontForBeaconTypeName];
    [self customizeAppearanceForUnselectedState];
}

- (void)setFontForBeaconTypeName {
    [_beaconTypeName setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
}

- (void)setValuesForBeaconTypeName:(NSString *)beaconTypeName andCheckmarkImage:(BOOL)isSelected {
    _beaconTypeName.text = beaconTypeName;
    
    if (isSelected) {
        [self customizeAppearanceForSelectedState];
    } else {
        [self customizeAppearanceForUnselectedState];
    }
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)customizeAppearanceForSelectedState {
    [_checkmarkImage setHidden:NO];
    _beaconTypeName.textColor = [UIColor sil_regularBlueColor];
}

- (void)customizeAppearanceForUnselectedState {
    [_checkmarkImage setHidden:YES];
    _beaconTypeName.textColor = [UIColor sil_subtleTextColor];
}

@end
