//
//  SILActivityBarViewController.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 2/10/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILActivityBarViewController.h"
#import "UIColor+SILColors.h"

static const CGFloat kScanAnimationDuration = 1.2f;
static const CGFloat kConnectAnimationDuration = 1.2f;

@interface SILActivityBarViewController ()
@property (weak, nonatomic) IBOutlet UIView *refreshDivider;
@property (weak, nonatomic) IBOutlet UIButton *activityButton;
@property (weak, nonatomic) IBOutlet UIButton *stopActivityButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftwayIndicatorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rightwayIndicatorImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightwayTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftwayLeadingConstraint;
@property (nonatomic) SILActivityBarState activityState;

@end

@implementation SILActivityBarViewController

#pragma mark - Properties

- (void)setAllowsStopActivity:(BOOL)allowsStopActivity {
    _allowsStopActivity = allowsStopActivity;
    _stopActivityButton.enabled = allowsStopActivity;
}

#pragma mark - ViewController Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftwayIndicatorImageView.hidden = self.rightwayIndicatorImageView.hidden = YES;
    CGFloat imageToTextSpacing = 8;
    self.activityButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, imageToTextSpacing);
    self.activityButton.titleEdgeInsets = UIEdgeInsetsMake(0, imageToTextSpacing, 0, 0);
    self.stopActivityButton.enabled = self.allowsStopActivity;
}

#pragma mark - Configuration

- (void)configureActivityBarWithState:(SILActivityBarState)state {
    [self.leftwayIndicatorImageView.layer removeAllAnimations];
    [self.rightwayIndicatorImageView.layer removeAllAnimations];
    BOOL active = state != SILActivityBarStateResting;
    self.view.backgroundColor = active ? [UIColor sil_siliconLabsRedColor] : [UIColor sil_refreshGreyColor];
    self.stopActivityButton.hidden = !active;
    self.refreshDivider.hidden = active;
    self.activityButton.hidden = active;
    self.activityState = state;
}

#pragma mark - Animation

- (void)scanningAnimationWithMessage:(NSString *)message {
    [self configureActivityBarWithState:SILActivityBarStateScanning];
    [self.stopActivityButton setTitle:message forState:UIControlStateNormal];
    [self repeatingScanningAnimation];
}

- (void)repeatingScanningAnimation {
    self.rightwayIndicatorImageView.transform = CGAffineTransformMakeRotation(M_PI);
    CGFloat originalPosition = CGRectGetWidth(self.view.bounds) + CGRectGetWidth(self.leftwayIndicatorImageView.bounds);
    CGFloat centerPosition = CGRectGetWidth(self.view.bounds) / 2;
    self.leftwayLeadingConstraint.constant = self.rightwayTrailingConstraint.constant = centerPosition;
    self.leftwayIndicatorImageView.alpha = self.rightwayIndicatorImageView.alpha = 0.75f;
    self.leftwayIndicatorImageView.hidden = self.rightwayIndicatorImageView.hidden = NO;
    __weak SILActivityBarViewController *weakSelf = self;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:kScanAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.leftwayIndicatorImageView.alpha = self.rightwayIndicatorImageView.alpha = 1;
        weakSelf.leftwayLeadingConstraint.constant = -CGRectGetWidth(self.leftwayIndicatorImageView.bounds);
        weakSelf.rightwayTrailingConstraint.constant = -CGRectGetWidth(self.rightwayIndicatorImageView.bounds);
        [weakSelf.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        weakSelf.leftwayIndicatorImageView.hidden = self.rightwayIndicatorImageView.hidden = YES;
        weakSelf.leftwayLeadingConstraint.constant = self.rightwayTrailingConstraint.constant = originalPosition;
        [weakSelf.view layoutIfNeeded];
        if (weakSelf.activityState == SILActivityBarStateScanning) {
            [weakSelf repeatingScanningAnimation];
        } else {
            [weakSelf.leftwayIndicatorImageView.layer removeAllAnimations];
            [weakSelf.rightwayIndicatorImageView.layer removeAllAnimations];
        }
    }];
}

- (void)connectingAnimationWithMessage:(NSString *)message {
    [self configureActivityBarWithState:SILActivityBarStateConnecting];
    [self.stopActivityButton setTitle:message forState:UIControlStateNormal];
    [self repeatingConnectingAnimation];
}

- (void)repeatingConnectingAnimation{
    self.rightwayIndicatorImageView.transform = CGAffineTransformMakeRotation(M_PI);
    CGFloat originalPosition = CGRectGetWidth(self.view.bounds) + CGRectGetWidth(self.rightwayIndicatorImageView.bounds);
    self.rightwayIndicatorImageView.hidden = NO;
    [self.view setNeedsLayout];
    __weak SILActivityBarViewController *weakSelf = self;
    [UIView animateWithDuration:kConnectAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.rightwayTrailingConstraint.constant = -CGRectGetWidth(self.rightwayIndicatorImageView.bounds);
        [weakSelf.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        weakSelf.rightwayIndicatorImageView.hidden = YES;
        weakSelf.rightwayTrailingConstraint.constant = originalPosition;
        [weakSelf.view layoutIfNeeded];
        if (weakSelf.activityState == SILActivityBarStateConnecting) {
            [weakSelf repeatingConnectingAnimation];
        } else {
            [weakSelf.leftwayIndicatorImageView.layer removeAllAnimations];
            [weakSelf.rightwayIndicatorImageView.layer removeAllAnimations];;
        }
    }];
}

#pragma mark - Actions

- (IBAction)didTapActivityButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(activityBarViewControllerDidTapActivityButton:)]) {
        [self.delegate activityBarViewControllerDidTapActivityButton:self];
    }
}

- (IBAction)didTapStopActivityButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(activityBarViewControllerDidTapStopActivityButton:)]) {
        [self.delegate activityBarViewControllerDidTapStopActivityButton:self];
    }
}

@end
