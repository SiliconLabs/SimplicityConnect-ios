//
//  SILDebugCharacteristicPropertyLabelViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/8/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SILDebugProperty;

@interface SILDebugCharacteristicPropertyView : UIView

@property (weak, nonatomic) IBOutlet UILabel *propertyTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *propertyIconImageView;

+ (void)addProperties:(NSArray *)properties toContainerView:(UIView *)containerView;

@end
