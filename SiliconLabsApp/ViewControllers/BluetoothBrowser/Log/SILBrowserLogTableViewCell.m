//
//  SILBrowserLogTableViewCell.m
//  BlueGecko
//
//  Created by Kamil Czajka on 29/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserLogTableViewCell.h"

@interface SILBrowserLogTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *logDataTimeInformationLabel;
@property (weak, nonatomic) IBOutlet UILabel *logDescriptionLabel;

@end

@implementation SILBrowserLogTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setApperance];
}

- (void)setApperance {
    [self setAppearanceForLogDataTimeInformationLabel];
    [self setAppearanceForLogDescriptionLabel];
}

- (void)setAppearanceForLogDataTimeInformationLabel {
    [self.logDataTimeInformationLabel setFont:[UIFont robotoBoldWithSize:[UIFont getMiddleFontSize]]];
    self.logDataTimeInformationLabel.textColor = [UIColor sil_primaryTextColor];
}

- (void)setAppearanceForLogDescriptionLabel {
    [self.logDescriptionLabel setFont:[UIFont robotoRegularWithSize:[UIFont getMiddleFontSize]]];
    self.logDescriptionLabel.textColor = [UIColor sil_primaryTextColor];
    self.logDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.logDescriptionLabel.numberOfLines = 0;
    [self.logDescriptionLabel sizeToFit];
    [self.logDescriptionLabel layoutIfNeeded];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setValues:(SILLogDataModel*)log {
    _logDataTimeInformationLabel.text = log.timestamp;
    _logDescriptionLabel.text = log.logDescription;
}

@end
