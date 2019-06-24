//
//  UIViewController+Containment.m
//  Chronability
//
//  Created by Ying Quan Tan on 5/7/15.
//  Copyright (c) 2015 IntrepidPursuits. All rights reserved.
//

#import "UIViewController+Containment.h"

@implementation UIViewController(Containment)

- (void)ip_addChildViewController:(UIViewController *)controller {
    [self ip_addChildViewController:controller toView:self.view];
}

- (void)ip_addChildViewController:(UIViewController *)controller toView:(UIView *)view {
    [self addChildViewController:controller];
    [view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (void)ip_removeFromParentViewController {
    [self willMoveToParentViewController:nil];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
    [self didMoveToParentViewController:nil];
}

@end
