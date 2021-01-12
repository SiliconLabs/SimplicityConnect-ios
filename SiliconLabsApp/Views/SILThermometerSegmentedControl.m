//
//  SILThermometerSegmentedControl.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/23/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILThermometerSegmentedControl.h"
#import "UIColor+SILColors.h"

@interface SILThermometerSegmentedControl ()

@end

@implementation SILThermometerSegmentedControl

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
    _selectedTextColor = selectedTextColor;
    [self updateContent];
}

- (void)setUnselectedTextColor:(UIColor *)unselectedTextColor {
    _unselectedTextColor = unselectedTextColor;
    [self updateContent];
}

- (void)setSelectedIndicatorColor:(UIColor *)selectedIndicatorColor {
    _selectedIndicatorColor = selectedIndicatorColor;
    [self updateContent];
}

- (void)setUnselectedIndicatorColor:(UIColor *)unselectedIndicatorColor {
    _unselectedIndicatorColor = unselectedIndicatorColor;
    [self updateContent];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    _selectedIndex = selectedIndex;

    [self updateContent];
}

- (void)updateContent {
    if (self.selectedIndex == 0) {
        self.firstSegmentLabel.textColor = [self selectedTextColor];
        self.firstSegmentIndicatorView.backgroundColor = [self selectedIndicatorColor];

        self.secondSegmentLabel.textColor = [self unselectedTextColor];
        self.secondSegmentIndicatorView.backgroundColor = [self unselectedIndicatorColor];
    } else {
        self.firstSegmentLabel.textColor = [self unselectedTextColor];
        self.firstSegmentIndicatorView.backgroundColor = [self unselectedIndicatorColor];

        self.secondSegmentLabel.textColor = [self selectedTextColor];
        self.secondSegmentIndicatorView.backgroundColor = [self selectedIndicatorColor];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateContent];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        CGPoint locationInView = [touch locationInView:self];
        if (CGRectContainsPoint(self.firstSegmentView.frame, locationInView)) {
            self.selectedIndex = 0;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        } else if (CGRectContainsPoint(self.secondSegmentView.frame, locationInView)) {
            self.selectedIndex = 1;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

@end
