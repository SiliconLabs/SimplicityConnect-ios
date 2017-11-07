//
//  SILAlertBarView.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/25/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface SILAlertBarView : UIView

@property (nonatomic) BOOL isAnimating;

- (void)configureLabel:(UILabel *)label revealConstraint:(NSLayoutConstraint *)revealConstraint hideConstraint:(NSLayoutConstraint *)hideConstraint;
///@discussion displayTime of 0 or less means the message should stay revealed indefinitely
- (void)revealAlertBarWithMessage:(NSString *)message revealTime:(CGFloat)revealTime displayTime:(CGFloat)displayTime;
///@discussion hides the bar if revealed indefinitely, will interrupt any animations that would otherwise hide it
- (void)hideBarIfRevealed:(CGFloat)hideTime;

@end
