//
//  SILBarGraphCollectionViewCell.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILBarGraphCollectionViewCell.h"
#import "UIColor+SILColors.h"

NSString * const SILBarGraphCollectionViewCellIdentifier = @"SILBarGraphCollectionViewCellIdentifier";

@interface SILBarGraphCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *valueView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *valueViewHeightConstraint;

@property (strong, nonatomic) CAGradientLayer *gradientLayer;

@property (strong, nonatomic) SILTemperatureMeasurement *temperatureMeasurement;
@property (assign, nonatomic) BOOL isFahrenheit;
@property (assign, nonatomic) NSRange range;

@end

@implementation SILBarGraphCollectionViewCell

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *_dateFormatter = nil;
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"h:mm a";
    }
    return _dateFormatter;
}

- (NSArray *)gradientColors {
    return @[
             (id)[[UIColor colorWithRed:80.0/255.0 green:78.0/255.0 blue:78.0/255.0 alpha:1.0 * self.alpha] CGColor],
             (id)[[UIColor colorWithRed:79.0/255.0 green:77.0/255.0 blue:77.0/255.0 alpha:0.5 * self.alpha] CGColor]
             ];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];

    self.gradientLayer.colors = [self gradientColors];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.valueView.backgroundColor = [UIColor clearColor];

    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.valueView.bounds;
    self.gradientLayer.colors = [self gradientColors];
    [self.valueView.layer insertSublayer:self.gradientLayer
                                 atIndex:0];
}

- (void)updateContent {
    double temperature;
    if(self.isFahrenheit) {
        temperature = [self.temperatureMeasurement valueInFahrenheit];
    } else {
        temperature = [self.temperatureMeasurement valueInCelsius];
    }

    UIFont *largeSize = [UIFont helveticaNeueLightWithSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 32 : 16];
    UIFont *smallSize = [UIFont helveticaNeueLightWithSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 20 : 11];

    NSString *valueString = [NSString stringWithFormat:@"%.1f°", temperature];
    NSMutableAttributedString *attributedValueString = [[NSMutableAttributedString alloc] initWithString:valueString
                                                                                              attributes:@{ NSFontAttributeName : largeSize }];
    [attributedValueString addAttributes:@{ NSFontAttributeName : smallSize }
                                   range:NSMakeRange([valueString rangeOfString:@"."].location + 1, 1)];
    self.valueLabel.attributedText = attributedValueString;

    double boundedTemperature = MAX(self.range.location, temperature);
    boundedTemperature = MIN(self.range.location + self.range.length, boundedTemperature);

    double normalizedTemperature = (boundedTemperature - self.range.location) / self.range.length;

    double scaledTemperature = _SILBarGraphCollectionViewCellMaxBarRatio * normalizedTemperature;

    CGFloat valueHeight = self.contentView.frame.size.height * scaledTemperature;
    self.valueViewHeightConstraint.constant = valueHeight;
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    self.gradientLayer.frame = CGRectMake(0, 0, self.valueView.bounds.size.width, valueHeight);
    [CATransaction commit];

    self.dateLabel.text = [[[self class] dateFormatter] stringFromDate:self.temperatureMeasurement.measurementDate];
}

- (void)configureWithTemperatureMeasurement:(SILTemperatureMeasurement *)temperatureMeasurement
                               isFahrenheit:(BOOL)isFahrenheit
                                      range:(NSRange)range {
    self.temperatureMeasurement = temperatureMeasurement;
    self.isFahrenheit = isFahrenheit;
    self.range = range;

    [self updateContent];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.temperatureMeasurement) {
        [self updateContent];
    }
}

@end
