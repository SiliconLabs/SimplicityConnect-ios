//
//  SILBarGraphCollectionViewCell.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILTemperatureMeasurement.h"

extern NSString * const SILBarGraphCollectionViewCellIdentifier;

@interface SILBarGraphCollectionViewCell : UICollectionViewCell

@property (assign, nonatomic) CGFloat SILBarGraphCollectionViewCellMaxBarRatio;

- (void)configureWithTemperatureMeasurement:(SILTemperatureMeasurement *)temperatureMeasurement
                               isFahrenheit:(BOOL)isFahrenheit
                                      range:(NSRange)range;

@end
