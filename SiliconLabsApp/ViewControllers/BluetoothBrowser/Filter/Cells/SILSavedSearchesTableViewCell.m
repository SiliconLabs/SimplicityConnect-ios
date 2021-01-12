//
//  SILSavedSearchesTableViewCell.m
//  BlueGecko
//
//  Created by Kamil Czajka on 13/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILSavedSearchesTableViewCell.h"
#import "NSString+SILBrowserNotifications.h"

@interface SILSavedSearchesTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *savedSearchDetailsLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (nonatomic, readwrite) NSUInteger index;

@end

@implementation SILSavedSearchesTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setAppearance];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setAppearance {
    [_savedSearchDetailsLabel setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
    [self customizeAppearanceForUnselectedState];
    [_savedSearchDetailsLabel sizeToFit];
}

- (void)setValuesForSavedSearch:(NSString*)savedSearchesText andIndex:(NSUInteger)index {
    _savedSearchDetailsLabel.text = savedSearchesText;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    _index = index;
}

- (void)customizeAppearanceForSelectedState {
    _savedSearchDetailsLabel.textColor = [UIColor sil_regularBlueColor];
}

- (void)customizeAppearanceForUnselectedState {
    _savedSearchDetailsLabel.textColor = [UIColor sil_subtleTextColor];
}

- (IBAction)deleteButtonWasTapped:(id)sender {
    [self postNotificationToViewModel];
}

- (void)postNotificationToViewModel {
    NSDictionary* userInfo = @{SILNotificationKeyIndex: @(_index)};
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDeleteSavedSearch object:self userInfo:userInfo];
}

@end
