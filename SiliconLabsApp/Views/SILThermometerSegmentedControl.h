//
//  SILThermometerSegmentedControl.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/23/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SILThermometerSegmentedControl : UIControl

@property (nonatomic) NSUInteger selectedIndex;

@property (strong, nonatomic) UIColor *selectedTextColor;
@property (strong, nonatomic) UIColor *unselectedTextColor;
@property (strong, nonatomic) UIColor *selectedIndicatorColor;
@property (strong, nonatomic) UIColor *unselectedIndicatorColor;

@property (weak, nonatomic) IBOutlet UIView *firstSegmentView;
@property (weak, nonatomic) IBOutlet UILabel *firstSegmentLabel;
@property (weak, nonatomic) IBOutlet UIView *firstSegmentIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *secondSegmentView;
@property (weak, nonatomic) IBOutlet UILabel *secondSegmentLabel;
@property (weak, nonatomic) IBOutlet UIView *secondSegmentIndicatorView;

@end
