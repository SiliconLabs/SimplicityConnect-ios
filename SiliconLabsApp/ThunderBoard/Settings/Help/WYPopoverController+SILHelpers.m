//
//  WYPopoverController+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "WYPopoverController+SILHelpers.h"

@implementation WYPopoverController (SILHelpers)

+ (WYPopoverController *)sil_presentCenterPopoverWithContentViewController:(UIViewController *)contentViewController
                                                  presentingViewController:(UIViewController *)presentingViewController
                                                                  delegate:(id<WYPopoverControllerDelegate>)delegate
                                                                  animated:(BOOL)animated {
    WYPopoverController *popoverController = [self sil_edgelessPopoverWithContentViewController:contentViewController
                                                                                       delegate:delegate];
    [WYPopoverController sil_presentPopoverFromCenter:popoverController
                             presentingViewController:presentingViewController
                                             animated:animated];
    return popoverController;
}

+ (WYPopoverController *)sil_edgelessPopoverWithContentViewController:(UIViewController *)contentViewController
                                                             delegate:(id<WYPopoverControllerDelegate>)delegate {
    WYPopoverController *popoverController = [[WYPopoverController alloc] initWithContentViewController:contentViewController];
    popoverController.delegate = delegate;
    popoverController.theme.outerCornerRadius = 16;
    popoverController.theme.innerCornerRadius = 16;
    popoverController.theme.arrowHeight = 0;
    popoverController.theme.overlayColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.35];
    popoverController.theme.outerShadowBlurRadius = 5.0f;
    popoverController.theme.outerShadowColor = [UIColor colorWithWhite:0 alpha:0.5f];
    popoverController.popoverLayoutMargins = UIEdgeInsetsZero;

    return popoverController;
}

+ (void)sil_presentPopoverFromCenter:(WYPopoverController *)popoverController
            presentingViewController:(UIViewController *)presentingViewController
                            animated:(BOOL)animated {
    [popoverController presentPopoverFromRect:CGRectMake(CGRectGetWidth(presentingViewController.view.bounds) * 0.5,
                                                         CGRectGetHeight(presentingViewController.view.bounds) * 0.5,
                                                         0,
                                                         0)
                                       inView:presentingViewController.view
                     permittedArrowDirections:WYPopoverArrowDirectionNone
                                     animated:animated
                                      options:(WYPopoverAnimationOptionFade)];
}

@end
