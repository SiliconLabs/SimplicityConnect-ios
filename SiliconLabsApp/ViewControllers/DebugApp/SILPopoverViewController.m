//
//  SILPopoverViewController.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/15/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILPopoverViewController.h"
#import "UIViewController+Containment.h"
#import <PureLayout/PureLayout.h>

static NSTimeInterval const kSILPopoverTransitionDuration = 0.33;
static CGFloat const kSILPopoverFinalBackgroundAlpha = 0.3;
static CGSize const kSILPopoverIPhoneSize = { 300.0, 400.0 };
static CGSize const kSILPopoverIPadSize = { 540.0, 400.0 };

@interface SILPopoverViewController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (strong, nonatomic) UIViewController *contentViewController;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation SILPopoverViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil contentViewController:(UIViewController *)contentViewController {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentViewController = contentViewController;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self ip_addChildViewController:self.contentViewController toView:self.contentView];
    [self.contentViewController.view autoPinEdgesToSuperviewEdges];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                            presentingController:(UIViewController *)presenting
                                                                                sourceController:(UIViewController *)source {
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return kSILPopoverTransitionDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    BOOL isPresenting = [toViewController isKindOfClass:[self class]];

    if (isPresenting) {
        SILPopoverViewController *toVC = (SILPopoverViewController *)toViewController;
        toVC.view.frame = fromViewController.view.bounds;
        [[transitionContext containerView] addSubview:toVC.view];
        toVC.view.alpha = 0;

        CGSize size = [self sizeForController:_contentViewController];
        toVC.contentViewWidthConstraint.constant = size.width;
        toVC.contentViewHeightConstraint.constant = size.height;
        [toVC.view layoutIfNeeded];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toVC.backgroundView.alpha = kSILPopoverFinalBackgroundAlpha;
            toVC.view.alpha = 1;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.alpha = 0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (CGSize)sizeForController:(UIViewController *)toVC {
    BOOL isIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGSize size = isIPad ? kSILPopoverIPadSize : kSILPopoverIPhoneSize;
    if ([toVC conformsToProtocol:@protocol(SILPopoverViewControllerSizeConstraints)]) {
        UIViewController <SILPopoverViewControllerSizeConstraints> *vc = (UIViewController <SILPopoverViewControllerSizeConstraints> *)toVC;
        if (isIPad) {
            if ([toVC respondsToSelector:@selector(popoverIPadSize)]) {
                size = [vc popoverIPadSize];
            }
        } else {
            if ([toVC respondsToSelector:@selector(popoverIPhoneSize)]) {
                size = [vc popoverIPhoneSize];
            }
        }
    }
    return size;
}

@end
